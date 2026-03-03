defmodule ConnectRPC do
  @moduledoc """
  ConnectRPC-compatible Plug for unary Connect requests.
  """

  @behaviour Plug

  import Plug.Conn

  alias ConnectRPC.Error
  alias ConnectRPC.Protocol
  alias ConnectRPC.Telemetry

  require Logger

  @type method_metadata :: %{
          required(:name) => String.t(),
          required(:function) => atom(),
          required(:request) => module(),
          required(:response) => module(),
          required(:client_streaming?) => boolean(),
          required(:server_streaming?) => boolean()
        }

  @type options :: %{
          handler: module(),
          methods: %{String.t() => method_metadata()},
          service_name: String.t(),
          read_body_fun: (Plug.Conn.t(), keyword() -> read_body_result()),
          read_body_opts: keyword(),
          debug_exceptions: boolean()
        }

  @type read_body_result ::
          {:ok, binary(), Plug.Conn.t()}
          | {:more, binary(), Plug.Conn.t()}
          | {:error, term()}
          | {:error, term(), Plug.Conn.t()}

  @impl Plug
  @spec init(keyword()) :: options()
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)

    case Code.ensure_loaded(handler) do
      {:module, _module} ->
        :ok

      {:error, _reason} ->
        raise ArgumentError, "Expected handler module #{inspect(handler)} to be available"
    end

    if !function_exported?(handler, :__connect_rpc__, 1) do
      raise ArgumentError,
            "Expected handler #{inspect(handler)} to `use ConnectRPC.Handler` and export __connect_rpc__/1"
    end

    %{
      handler: handler,
      methods: handler.__connect_rpc__(:methods),
      service_name: handler.__connect_rpc__(:service_name),
      read_body_fun: Keyword.get(opts, :read_body_fun, &Plug.Conn.read_body/2),
      read_body_opts: Keyword.get(opts, :read_body_opts, []),
      debug_exceptions: Keyword.get(opts, :debug_exceptions, false)
    }
  end

  @impl Plug
  @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
  def call(conn, opts) do
    case Protocol.validate_post(conn) do
      :ok ->
        process_connect_request(conn, opts)

      {:error, %Error{} = error, status} ->
        conn
        |> put_resp_header("allow", "POST")
        |> Protocol.send_error(error, status)
    end
  end

  defp process_connect_request(conn, opts) do
    with :ok <- Protocol.validate_protocol_version(conn),
         {:ok, codec} <- Protocol.negotiate_codec(conn),
         :ok <- Protocol.validate_compression(conn),
         {:ok, method_name} <- extract_method_name(conn),
         {:ok, method} <- lookup_method(opts, method_name),
         {:ok, body, conn} <- read_full_body(conn, opts),
         {:ok, request_struct} <- decode_request(codec, body, method.request, conn) do
      invoke_handler(conn, opts, method, codec, request_struct)
    else
      {:error, %Error{} = error, status} ->
        Protocol.send_error(conn, error, status)

      {:error, :missing_method} ->
        Protocol.send_error(
          conn,
          Error.new(:unimplemented, "Method is not implemented by #{opts.service_name}"),
          501
        )

      {:error, :unknown_method, method_name} ->
        Protocol.send_error(
          conn,
          Error.new(
            :unimplemented,
            "Method #{method_name} is not implemented by #{opts.service_name}"
          ),
          501
        )

      {:error, {:read_body, reason}, conn} ->
        map_body_read_error(conn, reason)

      {:error, {:decode, _reason}, conn} ->
        Protocol.send_error(conn, Error.new(:invalid_argument, "Invalid request body"), 400)
    end
  end

  defp extract_method_name(%Plug.Conn{path_info: [method_name]}) when byte_size(method_name) > 0 do
    {:ok, method_name}
  end

  defp extract_method_name(_conn), do: {:error, :missing_method}

  defp lookup_method(opts, method_name) do
    case Map.fetch(opts.methods, method_name) do
      {:ok, method} -> {:ok, method}
      :error -> {:error, :unknown_method, method_name}
    end
  end

  defp decode_request(codec, body, request_module, conn) do
    case codec.decode(body, request_module) do
      {:ok, request} -> {:ok, request}
      {:error, reason} -> {:error, {:decode, reason}, conn}
    end
  end

  defp invoke_handler(conn, opts, method, codec, request_struct) do
    metadata = %{
      service: opts.service_name,
      method: method.name,
      codec: codec.id(),
      path: conn.request_path
    }

    started_at = System.monotonic_time()
    Telemetry.emit_handler_start(metadata)

    try do
      result = apply(opts.handler, method.function, [request_struct, conn])
      handle_handler_result(conn, result, method, codec, metadata, started_at)
    rescue
      error in Error ->
        Telemetry.emit_handler_exception(started_at, metadata, :error, error, __STACKTRACE__)
        log_debug(metadata, started_at, Atom.to_string(error.code))
        Protocol.send_error(conn, error)

      exception ->
        Telemetry.emit_handler_exception(started_at, metadata, :error, exception, __STACKTRACE__)
        Logger.error(Exception.format(:error, exception, __STACKTRACE__))

        message =
          if opts.debug_exceptions do
            Exception.format_banner(:error, exception)
          else
            "internal error"
          end

        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, Error.new(:internal, message), 500)
    catch
      kind, reason ->
        stacktrace = __STACKTRACE__
        Telemetry.emit_handler_exception(started_at, metadata, kind, reason, stacktrace)

        Logger.error(Exception.format(kind, reason, stacktrace))

        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, Error.new(:internal, "internal error"), 500)
    end
  end

  defp handle_handler_result(conn, {:ok, response_struct}, method, codec, metadata, started_at) do
    case typecheck_response(response_struct, method.response) do
      :ok ->
        encode_and_send_success(conn, response_struct, codec, metadata, started_at, [])

      {:error, %Error{} = error} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, error, 500)
    end
  end

  defp handle_handler_result(conn, {:ok, response_struct, response_meta}, method, codec, metadata, started_at) do
    headers = normalize_response_headers(response_meta)

    case typecheck_response(response_struct, method.response) do
      :ok ->
        encode_and_send_success(conn, response_struct, codec, metadata, started_at, headers)

      {:error, %Error{} = error} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")
        conn |> apply_response_headers(headers) |> Protocol.send_error(error, 500)
    end
  end

  defp handle_handler_result(conn, {:error, %Error{} = error}, _method, _codec, metadata, started_at) do
    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))
    Protocol.send_error(conn, error)
  end

  defp handle_handler_result(conn, {:error, %Error{} = error, response_meta}, _method, _codec, metadata, started_at) do
    headers = normalize_response_headers(response_meta)

    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))
    conn |> apply_response_headers(headers) |> Protocol.send_error(error)
  end

  defp handle_handler_result(_conn, {:error, other}, _method, _codec, _metadata, _started_at) do
    raise RuntimeError,
          "Expected {:error, %ConnectRPC.Error{}}, got #{inspect(other)} from handler"
  end

  defp handle_handler_result(_conn, other, _method, _codec, _metadata, _started_at) do
    raise RuntimeError,
          "Expected {:ok, response_struct} or {:error, %ConnectRPC.Error{}}, got #{inspect(other)} from handler"
  end

  defp typecheck_response(%module{}, module), do: :ok

  defp typecheck_response(other, expected_module) do
    {:error, Error.new(:internal, "Expected #{inspect(expected_module)}, got #{inspect(other)}")}
  end

  defp encode_and_send_success(conn, response_struct, codec, metadata, started_at, headers) do
    case codec.encode(response_struct) do
      {:ok, body} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "ok")

        conn
        |> apply_response_headers(headers)
        |> put_resp_header("content-type", codec.media_type())
        |> send_resp(200, body)

      {:error, _reason} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, Error.new(:internal, "Failed to encode response"), 500)
    end
  end

  defp read_full_body(conn, opts) do
    do_read_full_body(conn, opts.read_body_fun, opts.read_body_opts, [])
  end

  defp do_read_full_body(conn, read_body_fun, read_body_opts, acc) do
    case read_body_fun.(conn, read_body_opts) do
      {:ok, chunk, conn} ->
        body = [chunk | acc] |> Enum.reverse() |> IO.iodata_to_binary()
        {:ok, body, conn}

      {:more, chunk, conn} ->
        do_read_full_body(conn, read_body_fun, read_body_opts, [chunk | acc])

      {:error, reason} ->
        {:error, {:read_body, reason}, conn}

      {:error, reason, conn} ->
        {:error, {:read_body, reason}, conn}
    end
  end

  defp map_body_read_error(conn, :too_large) do
    Protocol.send_error(conn, Error.new(:resource_exhausted, "Request body too large"), 413)
  end

  defp map_body_read_error(conn, :timeout) do
    Protocol.send_error(conn, Error.new(:deadline_exceeded, "Request body read timed out"), 504)
  end

  defp map_body_read_error(conn, _reason) do
    Protocol.send_error(conn, Error.new(:internal, "Failed to read request body"), 500)
  end

  defp log_debug(metadata, started_at, status) do
    duration_native = System.monotonic_time() - started_at
    duration_ms = :erlang.convert_time_unit(duration_native, :native, :microsecond) / 1000

    Logger.debug(
      "ConnectRPC #{metadata.service}/#{metadata.method} codec=#{metadata.codec} " <>
        "duration=#{format_ms(duration_ms)}ms status=#{status}"
    )
  end

  defp format_ms(value) do
    :erlang.float_to_binary(value, decimals: 1)
  end

  defp normalize_response_headers(nil), do: []
  defp normalize_response_headers(%{} = meta), do: meta[:headers] || meta["headers"] || []

  defp normalize_response_headers(meta) when is_list(meta) do
    if Keyword.keyword?(meta) do
      Keyword.get(meta, :headers, [])
    else
      meta
    end
  end

  defp normalize_response_headers(_meta), do: []

  defp apply_response_headers(conn, []), do: conn

  defp apply_response_headers(conn, headers) do
    Enum.reduce(headers, conn, fn header, conn ->
      case normalize_header_entry(header) do
        [] ->
          conn

        entries ->
          Enum.reduce(entries, conn, fn {name, value}, conn ->
            append_resp_header(conn, name, value)
          end)
      end
    end)
  end

  defp normalize_header_entry({name, value}) when is_binary(name) and is_binary(value) do
    [{String.downcase(name), value}]
  end

  defp normalize_header_entry(%{name: name, value: values}) when is_binary(name) and is_list(values) do
    Enum.map(values, fn value -> {String.downcase(name), to_string(value)} end)
  end

  defp normalize_header_entry(%{"name" => name, "value" => values}) when is_binary(name) and is_list(values) do
    Enum.map(values, fn value -> {String.downcase(name), to_string(value)} end)
  end

  defp normalize_header_entry(_entry), do: []

  defp append_resp_header(conn, name, value) do
    update_resp_header(conn, name, value, fn existing -> "#{existing},#{value}" end)
  end
end
