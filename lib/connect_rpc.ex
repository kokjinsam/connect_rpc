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

  @double_send_error_message "Handler sent a response directly via Plug.Conn. Use {:ok, response} or {:error, %ConnectRPC.Error{}} return values instead."
  @body_consumed_error_message "Request body already consumed by an upstream parser. Exclude ConnectRPC paths from Plug.Parsers using the :pass option."
  @header_name_regex ~r/^[!#$%&'*+\-.^_`|~0-9a-z]+$/

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
          codecs: [module()],
          read_body_opts: keyword(),
          debug_exceptions: boolean()
        }

  @type response_metadata :: %{
          headers: list(),
          trailers: list()
        }

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

    init_opts = %{
      handler: handler,
      methods: handler.__connect_rpc__(:methods),
      service_name: handler.__connect_rpc__(:service_name),
      codecs: normalize_codecs!(Keyword.get(opts, :codecs, default_codecs())),
      read_body_opts: Keyword.get(opts, :read_body_opts, []),
      debug_exceptions: Keyword.get(opts, :debug_exceptions, false)
    }

    # Internal testing seam — not part of the public API
    case Keyword.fetch(opts, :read_body_fun) do
      {:ok, fun} when is_function(fun, 2) -> Map.put(init_opts, :read_body_fun, fun)
      _ -> init_opts
    end
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
    with {:ok, codec} <- Protocol.negotiate_codec(conn, opts.codecs),
         :ok <- Protocol.validate_protocol_version(conn),
         :ok <- Protocol.validate_compression(conn),
         :ok <- validate_body_parser_ownership(conn),
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

      {:error, :body_already_consumed} ->
        raise RuntimeError, @body_consumed_error_message
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
      codec: codec.media_type(),
      path: conn.request_path
    }

    started_at = System.monotonic_time()
    Telemetry.emit_handler_start(metadata)

    marker = {:connect_rpc_handler_sent, make_ref()}
    conn = attach_send_guard(conn, marker)
    Process.delete(marker)

    try do
      case run_handler(conn, opts, method, request_struct, metadata, started_at, marker) do
        {:ok, result} ->
          ensure_handler_did_not_send_response!(marker)

          handle_handler_result_with_rescue(
            conn,
            result,
            method,
            codec,
            metadata,
            started_at,
            opts.debug_exceptions
          )

        {:response, response_conn} ->
          response_conn
      end
    after
      Process.delete(marker)
    end
  end

  defp run_handler(conn, opts, method, request_struct, metadata, started_at, marker) do
    {:ok, apply(opts.handler, method.function, [request_struct, conn])}
  rescue
    error in Error ->
      ensure_handler_did_not_send_response!(marker)
      Telemetry.emit_handler_exception(started_at, metadata, :error, error, __STACKTRACE__)
      log_debug(metadata, started_at, Atom.to_string(error.code))
      {:response, Protocol.send_error(conn, error)}

    exception ->
      ensure_handler_did_not_send_response!(marker)
      Telemetry.emit_handler_exception(started_at, metadata, :error, exception, __STACKTRACE__)
      Logger.error(Exception.format(:error, exception, __STACKTRACE__))

      message =
        if opts.debug_exceptions do
          Exception.format_banner(:error, exception)
        else
          "internal error"
        end

      log_debug(metadata, started_at, "internal")
      {:response, Protocol.send_error(conn, Error.new(:internal, message), 500)}
  catch
    kind, reason ->
      ensure_handler_did_not_send_response!(marker)
      stacktrace = __STACKTRACE__
      Telemetry.emit_handler_exception(started_at, metadata, kind, reason, stacktrace)

      Logger.error(Exception.format(kind, reason, stacktrace))

      log_debug(metadata, started_at, "internal")
      {:response, Protocol.send_error(conn, Error.new(:internal, "internal error"), 500)}
  end

  defp handle_handler_result_with_rescue(conn, result, method, codec, metadata, started_at, debug_exceptions) do
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
        if debug_exceptions do
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

  defp handle_handler_result(conn, {:ok, response_struct}, method, codec, metadata, started_at) do
    case typecheck_response(response_struct, method.response) do
      :ok ->
        encode_and_send_success(
          conn,
          response_struct,
          codec,
          metadata,
          started_at,
          %{headers: [], trailers: []}
        )

      {:error, %Error{} = error} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, error, 500)
    end
  end

  defp handle_handler_result(conn, {:ok, response_struct, response_meta}, method, codec, metadata, started_at) do
    response_metadata = normalize_response_metadata(response_meta)

    case typecheck_response(response_struct, method.response) do
      :ok ->
        encode_and_send_success(conn, response_struct, codec, metadata, started_at, response_metadata)

      {:error, %Error{} = error} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")

        conn
        |> apply_response_metadata(response_metadata)
        |> Protocol.send_error(error, 500)
    end
  end

  defp handle_handler_result(conn, {:error, %Error{} = error}, _method, _codec, metadata, started_at) do
    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))
    Protocol.send_error(conn, error)
  end

  defp handle_handler_result(conn, {:error, %Error{} = error, response_meta}, _method, _codec, metadata, started_at) do
    response_metadata = normalize_response_metadata(response_meta)

    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))

    conn
    |> apply_response_metadata(response_metadata)
    |> Protocol.send_error(error)
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

  defp encode_and_send_success(conn, response_struct, codec, metadata, started_at, response_metadata) do
    case codec.encode(response_struct) do
      {:ok, body} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "ok")

        conn
        |> apply_response_metadata(response_metadata)
        |> put_resp_header("content-type", codec.media_type())
        |> send_resp(200, body)

      {:error, _reason} ->
        Telemetry.emit_handler_stop(started_at, metadata)
        log_debug(metadata, started_at, "internal")
        Protocol.send_error(conn, Error.new(:internal, "Failed to encode response"), 500)
    end
  end

  defp read_full_body(conn, opts) do
    read_body_fun = Map.get(opts, :read_body_fun, &Plug.Conn.read_body/2)
    do_read_full_body(conn, read_body_fun, opts.read_body_opts, [])
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

  defp validate_body_parser_ownership(%Plug.Conn{body_params: %Plug.Conn.Unfetched{}}), do: :ok
  defp validate_body_parser_ownership(_conn), do: {:error, :body_already_consumed}

  defp attach_send_guard(conn, marker) do
    register_before_send(conn, fn conn ->
      Process.put(marker, true)
      conn
    end)
  end

  defp ensure_handler_did_not_send_response!(marker) do
    if Process.delete(marker) do
      raise RuntimeError, @double_send_error_message
    else
      :ok
    end
  end

  defp default_codecs do
    [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON]
  end

  defp normalize_codecs!(codecs) when is_list(codecs) do
    Enum.map(codecs, &validate_codec!/1)
  end

  defp normalize_codecs!(other) do
    raise ArgumentError, "Expected :codecs to be a list of codec modules, got #{inspect(other)}"
  end

  defp validate_codec!(codec) when is_atom(codec) do
    case Code.ensure_loaded(codec) do
      {:module, _module} ->
        validate_codec_callbacks!(codec)
        validate_codec_media_type!(codec)
        codec

      {:error, reason} ->
        raise ArgumentError, "Expected codec module #{inspect(codec)} to be available, got: #{inspect(reason)}"
    end
  end

  defp validate_codec!(codec) do
    raise ArgumentError, "Expected codec entry to be a module, got #{inspect(codec)}"
  end

  defp validate_codec_callbacks!(codec) do
    callbacks = [media_type: 0, encode: 1, decode: 2]

    Enum.each(callbacks, fn {name, arity} ->
      if !function_exported?(codec, name, arity) do
        raise ArgumentError,
              "Codec #{inspect(codec)} must implement #{name}/#{arity}"
      end
    end)
  end

  defp validate_codec_media_type!(codec) do
    media_type = codec.media_type()

    if !is_binary(media_type) or media_type == "" do
      raise ArgumentError,
            "Codec #{inspect(codec)} must return a non-empty binary media type from media_type/0"
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

  defp normalize_response_metadata(nil), do: %{headers: [], trailers: []}

  defp normalize_response_metadata(%{} = meta) do
    headers = meta[:headers] || meta["headers"] || meta[:response_headers] || meta["response_headers"]
    trailers = meta[:trailers] || meta["trailers"] || meta[:response_trailers] || meta["response_trailers"]

    %{
      headers: normalize_metadata_entries!(headers, :headers),
      trailers: normalize_metadata_entries!(trailers, :trailers)
    }
  end

  defp normalize_response_metadata(meta) when is_list(meta) do
    if Keyword.keyword?(meta) do
      headers = Keyword.get(meta, :headers) || Keyword.get(meta, :response_headers)
      trailers = Keyword.get(meta, :trailers) || Keyword.get(meta, :response_trailers)

      %{
        headers: normalize_metadata_entries!(headers, :headers),
        trailers: normalize_metadata_entries!(trailers, :trailers)
      }
    else
      %{headers: normalize_metadata_entries!(meta, :headers), trailers: []}
    end
  end

  defp normalize_response_metadata(meta) do
    raise ArgumentError,
          "Unsupported response metadata #{inspect(meta)}. " <>
            "Expected nil, a map, a keyword list, or a list of metadata entries."
  end

  defp normalize_metadata_entries!(nil, _kind), do: []

  defp normalize_metadata_entries!(entries, kind) when is_list(entries) do
    entries
    |> Enum.with_index()
    |> Enum.flat_map(fn {entry, index} ->
      normalize_metadata_entry!(entry, kind, index)
    end)
  end

  defp normalize_metadata_entries!(entries, kind) do
    raise ArgumentError,
          "Expected #{kind} metadata to be a list, got: #{inspect(entries)}"
  end

  defp normalize_metadata_entry!({name, value}, kind, index) when is_binary(name) and is_binary(value) do
    [{normalize_header_name!(name, kind, index), normalize_header_value!(value, kind, index)}]
  end

  defp normalize_metadata_entry!({name, values}, kind, index) when is_binary(name) and is_list(values) do
    normalized_name = normalize_header_name!(name, kind, index)

    Enum.with_index(values, fn value, value_index ->
      {normalized_name, normalize_header_value!(value, kind, {index, value_index})}
    end)
  end

  defp normalize_metadata_entry!(%{} = entry, kind, index) do
    name = metadata_entry_name(entry, kind, index)
    values = metadata_entry_values(entry, kind, index)
    normalized_name = normalize_header_name!(name, kind, index)

    Enum.with_index(values, fn value, value_index ->
      {normalized_name, normalize_header_value!(value, kind, {index, value_index})}
    end)
  end

  defp normalize_metadata_entry!(entry, kind, index) do
    raise ArgumentError,
          "Unsupported #{kind} metadata entry at index #{index}: #{inspect(entry)}. " <>
            "Expected {name, value}, {name, [values]}, or %{name: name, value: value_or_values}."
  end

  defp metadata_entry_name(entry, kind, index) do
    case Map.get(entry, :name) || Map.get(entry, "name") do
      name when is_binary(name) ->
        name

      other ->
        raise ArgumentError,
              "Expected #{kind} metadata entry #{index} to include a binary :name, got: #{inspect(other)}"
    end
  end

  defp metadata_entry_values(entry, kind, index) do
    case Map.get(entry, :value) || Map.get(entry, "value") do
      value when is_binary(value) ->
        [value]

      values when is_list(values) ->
        values

      other ->
        raise ArgumentError,
              "Expected #{kind} metadata entry #{index} to include :value as a binary or list, got: #{inspect(other)}"
    end
  end

  defp normalize_header_name!(name, kind, index) do
    normalized_name =
      name
      |> String.trim()
      |> String.downcase()

    cond do
      normalized_name == "" ->
        raise ArgumentError,
              "Expected #{kind} metadata entry #{format_metadata_index(index)} to have a non-empty header name"

      Regex.match?(@header_name_regex, normalized_name) ->
        normalized_name

      true ->
        raise ArgumentError,
              "Invalid #{kind} header name #{inspect(name)} at #{format_metadata_index(index)}. " <>
                "Header names must use RFC 7230 token characters."
    end
  end

  defp normalize_header_value!(value, kind, index) do
    normalized_value = to_string(value)

    if String.contains?(normalized_value, "\r") or String.contains?(normalized_value, "\n") do
      raise ArgumentError,
            "Invalid #{kind} header value at #{format_metadata_index(index)}. " <>
              "Header values must not contain CR/LF characters."
    end

    normalized_value
  end

  defp format_metadata_index({entry_index, value_index}), do: "#{entry_index}.#{value_index}"
  defp format_metadata_index(index), do: to_string(index)

  defp apply_response_metadata(conn, %{headers: headers, trailers: trailers}) do
    conn
    |> apply_response_headers(headers)
    |> apply_response_trailers(trailers)
  end

  defp apply_response_trailers(conn, []), do: conn

  defp apply_response_trailers(conn, trailers) do
    Enum.reduce(trailers, conn, fn {name, value}, conn ->
      append_resp_header(conn, trailer_header_name(name), value)
    end)
  end

  defp apply_response_headers(conn, []), do: conn

  defp apply_response_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {name, value}, conn ->
      append_resp_header(conn, name, value)
    end)
  end

  defp append_resp_header(conn, name, value) do
    %{conn | resp_headers: conn.resp_headers ++ [{name, value}]}
  end

  defp trailer_header_name("trailer-" <> _rest = name), do: name
  defp trailer_header_name(name), do: "trailer-" <> name
end
