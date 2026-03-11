defmodule ConnectRPC.Plug.Handler do
  @moduledoc false

  @behaviour Plug

  alias ConnectRPC.Context
  alias ConnectRPC.Error
  alias ConnectRPC.Protocol
  alias Plug.Conn.Unfetched

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> ensure_parser_ran!()
    |> maybe_send_parser_error()
    |> maybe_initialize_context()
    |> maybe_cast_request_body()
  end

  defp ensure_parser_ran!(conn) do
    case conn.private[:connect_rpc_valid] do
      nil ->
        if match?(%Unfetched{}, conn.body_params) and
             match?(%Unfetched{}, conn.params) do
          raise RuntimeError, "Add ConnectRPC.Parser to Plug.Parsers in your endpoint."
        else
          errors = collect_validation_errors(conn)

          conn
          |> Plug.Conn.put_private(:connect_rpc_valid, false)
          |> Plug.Conn.put_private(:connect_rpc_errors, errors)
        end

      _value ->
        conn
    end
  end

  defp collect_validation_errors(conn) do
    with :ok <- Protocol.validate_post(conn),
         {:ok, _codec} <- Protocol.negotiate_codec(conn),
         :ok <- Protocol.validate_protocol_version(conn) do
      [{Error.new(:unknown, "Unsupported content type"), 415}]
    else
      {:error, error, status} -> [{error, status}]
    end
  end

  defp maybe_send_parser_error(%Plug.Conn{halted: true} = conn), do: conn

  defp maybe_send_parser_error(conn) do
    if conn.private[:connect_rpc_valid] == false do
      {error, status} =
        case conn.private[:connect_rpc_errors] || [] do
          [{error, status} | _rest] -> {error, status}
          [] -> {Error.new(:internal, "Invalid ConnectRPC request"), 500}
        end

      conn
      |> maybe_put_allow_header(status)
      |> Protocol.send_error(error, status)
      |> Plug.Conn.halt()
    else
      conn
    end
  end

  defp maybe_put_allow_header(conn, 405), do: Plug.Conn.put_resp_header(conn, "allow", "POST")
  defp maybe_put_allow_header(conn, _status), do: conn

  defp maybe_initialize_context(%Plug.Conn{halted: true} = conn), do: conn

  defp maybe_initialize_context(conn) do
    case conn.private[:connect_rpc_context] do
      %Context{} -> conn
      _other -> Plug.Conn.put_private(conn, :connect_rpc_context, Context.new())
    end
  end

  defp maybe_cast_request_body(%Plug.Conn{halted: true} = conn), do: conn

  defp maybe_cast_request_body(conn) do
    rpc_meta =
      conn.private[:connect_rpc_rpc] ||
        raise RuntimeError, "Missing ConnectRPC RPC metadata. Ensure rpc/3 routes are configured correctly."

    case cast_request(conn, conn.private[:connect_rpc_body_format], rpc_meta.request) do
      {:ok, request_struct} ->
        Plug.Conn.assign(conn, :connect_rpc_request, request_struct)

      {:error, %Error{} = error} ->
        conn
        |> Protocol.send_error(error, 400)
        |> Plug.Conn.halt()
    end
  end

  defp cast_request(conn, :json_map, request_module) do
    body_params = conn.body_params || %{}

    try do
      case Protobuf.JSON.from_decoded(body_params, request_module) do
        {:ok, %_{} = request_struct} -> {:ok, request_struct}
        {:ok, _other} -> {:error, Error.new(:invalid_argument, "Invalid request body")}
        {:error, _reason} -> {:error, Error.new(:invalid_argument, "Invalid request body")}
      end
    rescue
      _exception -> {:error, Error.new(:invalid_argument, "Invalid request body")}
    end
  end

  defp cast_request(conn, :raw_binary, request_module) do
    raw_body =
      case conn.body_params do
        %{"_raw" => body} when is_binary(body) -> body
        _other -> nil
      end

    if is_binary(raw_body) do
      try do
        case request_module.decode(raw_body) do
          {:ok, %_{} = request_struct} -> {:ok, request_struct}
          %_{} = request_struct -> {:ok, request_struct}
          _other -> {:error, Error.new(:invalid_argument, "Invalid request body")}
        end
      rescue
        _exception -> {:error, Error.new(:invalid_argument, "Invalid request body")}
      end
    else
      {:error, Error.new(:invalid_argument, "Invalid request body")}
    end
  end

  defp cast_request(_conn, _body_format, _request_module) do
    {:error, Error.new(:invalid_argument, "Invalid request body")}
  end
end
