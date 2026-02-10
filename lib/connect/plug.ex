defmodule Connect.Plug do
  @moduledoc """
  Main ConnectRPC plug. Mount via `Connect.Router.connect_service/2` or
  `forward` in your Phoenix router.

  ## Options

    * `:service` - the module using `Connect.Service` (provides `__rpc_calls__/0`)
    * `:impl` - the module implementing the RPC handler functions
    * `:require_version` - whether to require `Connect-Protocol-Version: 1`
      header (default: `true`)

  ## Example

      forward "/eliza.v1.ElizaService", Connect.Plug,
        service: Eliza.V1.ElizaService,
        impl: MyApp.Eliza.Server
  """

  @behaviour Plug

  import Plug.Conn
  require Logger
  alias Connect.{Protocol, Codec, Envelope, Stream, Error}

  @max_body_bytes 8_000_000

  @impl true
  def init(opts) do
    service = Keyword.fetch!(opts, :service)
    impl = Keyword.fetch!(opts, :impl)
    require_version = Keyword.get(opts, :require_version, true)

    impl_lookup = build_impl_lookup(impl)

    rpc_map =
      service.__rpc_calls__()
      |> Enum.into(%{}, fn {name, {req, _req_stream}, {resp, resp_stream}, _opts} ->
        impl_name = name |> Atom.to_string() |> Macro.underscore()
        impl_function = Map.get(impl_lookup, impl_name)

        if is_nil(impl_function) do
          Logger.warning(
            "ConnectRPC: Service defines #{name} but #{inspect(impl)} has no #{impl_name}/2"
          )
        end

        {Atom.to_string(name),
         %{
           impl_function: impl_function,
           request_type: req,
           response_type: resp,
           server_streaming?: resp_stream
         }}
      end)

    %{impl: impl, rpc_map: rpc_map, require_version: require_version}
  end

  @impl true
  def call(conn, %{rpc_map: rpc_map, impl: impl} = config) do
    method_name = List.last(conn.path_info)

    case Map.get(rpc_map, method_name) do
      nil ->
        Error.send_unary(conn, Error.new("unimplemented", "Method not found"))

      rpc_def ->
        handle_rpc(conn, impl, rpc_def, config)
    end
  end

  defp handle_rpc(conn, impl, rpc, config) do
    with :ok <- Protocol.validate_method(conn),
         :ok <- Protocol.validate_protocol_version(conn, required: config.require_version),
         {:ok, spec} <- Protocol.parse_content_type(conn),
         :ok <- validate_wire_mode(spec.wire_mode, rpc.server_streaming?) do
      case read_raw_body(conn) do
        {:ok, body, conn} ->
          if rpc.server_streaming? do
            execute_streaming(conn, impl, rpc, body, spec.codec)
          else
            execute_unary(conn, impl, rpc, body, spec.codec)
          end

        _ ->
          Error.send_unary(conn, Error.new("data_loss", "Unable to read request body"))
      end
    else
      {:error, :method_not_allowed} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          405,
          Jason.encode!(%{"code" => "unimplemented", "message" => "Only POST is supported"})
        )

      {:error, :unsupported_protocol_version} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{
            "code" => "invalid_argument",
            "message" => "missing required header: set Connect-Protocol-Version to \"1\""
          })
        )

      {:error, :unsupported_media_type} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          415,
          Jason.encode!(%{"code" => "unknown", "message" => "Unsupported media type"})
        )

      {:error, :wire_mode_mismatch} ->
        Error.send_unary(
          conn,
          Error.new("invalid_argument", "Content type does not match RPC type")
        )
    end
  end

  # --- Unary ---

  defp execute_unary(conn, impl, rpc, body, codec) do
    if rpc.impl_function do
      with {:ok, request} <- Codec.decode(body, rpc.request_type, codec) do
        try do
          case apply(impl, rpc.impl_function, [request, nil]) do
            %Error{} = error ->
              Error.send_unary(conn, error)

            response ->
              encoded = Codec.encode(response, codec)

              conn
              |> put_resp_content_type(Protocol.mime_type(codec))
              |> send_resp(200, encoded)
          end
        rescue
          e ->
            Logger.error("ConnectRPC unary handler error: #{Exception.message(e)}")
            Error.send_unary(conn, Error.new("internal", "Internal server error"))
        end
      else
        {:error, _} ->
          Error.send_unary(conn, Error.new("invalid_argument", "Malformed request body"))
      end
    else
      Error.send_unary(conn, Error.new("unimplemented", "Not implemented"))
    end
  end

  # --- Server Streaming ---

  defp execute_streaming(conn, impl, rpc, body, codec) do
    if rpc.impl_function do
      with {:ok, request} <- decode_streaming_request(body, rpc.request_type, codec) do
        conn =
          conn
          |> put_resp_content_type(Protocol.stream_mime_type(codec))
          |> send_chunked(200)

        stream = Stream.new(conn, codec)

        try do
          case apply(impl, rpc.impl_function, [request, stream]) do
            %Stream{conn: final_conn} ->
              finish_stream(final_conn)

            {:ok, %Stream{conn: final_conn}} ->
              finish_stream(final_conn)

            {:error, %Error{} = error} ->
              finish_stream(stream.conn, Error.to_end_stream(error))

            other ->
              Logger.warning(
                "ConnectRPC: Streaming handler returned unexpected value: #{inspect(other)}"
              )

              finish_stream(
                stream.conn,
                Error.to_end_stream(Error.new("internal", "Handler error"))
              )
          end
        rescue
          e ->
            Logger.error("ConnectRPC stream handler error: #{Exception.message(e)}")

            finish_stream(
              stream.conn,
              Error.to_end_stream(Error.new("internal", "Stream failed"))
            )
        end
      else
        {:error, _} ->
          Error.send_unary(conn, Error.new("invalid_argument", "Malformed request body"))
      end
    else
      Error.send_unary(conn, Error.new("unimplemented", "Not implemented"))
    end
  end

  # --- Helpers ---

  defp decode_streaming_request(body, request_type, codec) do
    case Connect.Envelope.Reader.read_single_message(body, max_bytes: @max_body_bytes) do
      {:ok, payload, _end_stream} ->
        Codec.decode(payload, request_type, codec)

      {:error, _} = err ->
        err
    end
  end

  defp finish_stream(conn, metadata \\ %{}) do
    case chunk(conn, Envelope.wrap_end(metadata)) do
      {:ok, final_conn} -> final_conn
      {:error, _} -> conn
    end
  end

  defp validate_wire_mode(:unary, false), do: :ok
  defp validate_wire_mode(:streaming, true), do: :ok
  defp validate_wire_mode(_, _), do: {:error, :wire_mode_mismatch}

  defp read_raw_body(conn) do
    case conn.private[:raw_body] do
      nil -> read_body(conn, length: @max_body_bytes)
      iodata -> {:ok, IO.iodata_to_binary(iodata), conn}
    end
  end

  defp build_impl_lookup(impl) do
    impl.__info__(:functions)
    |> Enum.reduce(%{}, fn {fun, arity}, acc ->
      if arity == 2, do: Map.put(acc, Atom.to_string(fun), fun), else: acc
    end)
  end
end
