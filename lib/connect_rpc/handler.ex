defmodule ConnectRPC.Handler do
  @moduledoc """
  Macro for defining ConnectRPC handlers as Plug modules.
  """

  import Plug.Conn

  alias ConnectRPC.Error
  alias ConnectRPC.Protocol
  alias ConnectRPC.Telemetry

  require Logger

  @double_send_error_message "Handler sent a response directly via Plug.Conn. Use {:ok, response} or {:error, %ConnectRPC.Error{}} return values instead."
  @metadata_name_regex ~r/^[0-9a-z_.-]+$/
  @ascii_metadata_value_regex ~r/^[\x20-\x7E]+$/

  defmacro __using__(opts \\ []) do
    debug_exceptions = Keyword.get(opts, :debug_exceptions, false)

    quote do
      @behaviour Plug

      import Plug.Conn

      alias ConnectRPC.Error

      @connect_rpc_debug_exceptions unquote(debug_exceptions)

      @impl Plug
      def init(action) when is_atom(action), do: action

      @impl Plug
      def call(conn, action) do
        ConnectRPC.Handler.__call__(conn, action, __MODULE__, @connect_rpc_debug_exceptions)
      end

      defoverridable init: 1, call: 2
    end
  end

  @spec __call__(Plug.Conn.t(), atom(), module(), boolean()) :: Plug.Conn.t()
  def __call__(conn, action, handler_module, debug_exceptions) do
    rpc_meta = conn.private.connect_rpc_rpc
    request_struct = conn.assigns.connect_rpc_request
    codec = conn.assigns.connect_rpc_codec

    metadata = %{
      service: rpc_meta.service_name,
      method: rpc_method_name(conn, rpc_meta, action),
      codec: codec.media_type(),
      path: conn.request_path
    }

    started_at = System.monotonic_time()
    Telemetry.emit_handler_start(metadata)

    marker = {:connect_rpc_handler_sent, make_ref()}
    guarded_conn = attach_send_guard(conn, marker)
    Process.delete(marker)

    try do
      case run_handler(
             guarded_conn,
             handler_module,
             action,
             request_struct,
             metadata,
             started_at,
             marker,
             debug_exceptions
           ) do
        {:ok, result} ->
          ensure_handler_did_not_send_response!(marker)

          handle_handler_result_with_rescue(
            guarded_conn,
            result,
            rpc_meta,
            codec,
            metadata,
            started_at,
            debug_exceptions
          )

        {:response, response_conn} ->
          response_conn
      end
    after
      Process.delete(marker)
    end
  end

  defp run_handler(conn, handler_module, action, request_struct, metadata, started_at, marker, debug_exceptions) do
    {:ok, apply(handler_module, action, [conn, request_struct])}
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
        if debug_exceptions do
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

  defp handle_handler_result_with_rescue(conn, result, rpc_meta, codec, metadata, started_at, debug_exceptions) do
    handle_handler_result(conn, result, rpc_meta, codec, metadata, started_at)
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

  defp handle_handler_result(conn, {:ok, response_struct}, rpc_meta, codec, metadata, started_at) do
    case typecheck_response(response_struct, rpc_meta.response) do
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

  defp handle_handler_result(conn, {:ok, response_struct, response_meta}, rpc_meta, codec, metadata, started_at) do
    response_metadata = normalize_response_metadata(response_meta)

    case typecheck_response(response_struct, rpc_meta.response) do
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

  defp handle_handler_result(conn, {:error, %Error{} = error}, _rpc_meta, _codec, metadata, started_at) do
    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))
    Protocol.send_error(conn, error)
  end

  defp handle_handler_result(conn, {:error, %Error{} = error, response_meta}, _rpc_meta, _codec, metadata, started_at) do
    response_metadata = normalize_response_metadata(response_meta)

    Telemetry.emit_handler_stop(started_at, metadata)
    log_debug(metadata, started_at, Atom.to_string(error.code))

    conn
    |> apply_response_metadata(response_metadata)
    |> Protocol.send_error(error)
  end

  defp handle_handler_result(_conn, {:error, other}, _rpc_meta, _codec, _metadata, _started_at) do
    raise RuntimeError,
          "Expected {:error, %ConnectRPC.Error{}}, got #{inspect(other)} from handler"
  end

  defp handle_handler_result(_conn, other, _rpc_meta, _codec, _metadata, _started_at) do
    raise RuntimeError,
          "Expected {:ok, response_struct} or {:error, %ConnectRPC.Error{}}, got #{inspect(other)} from handler"
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

  defp typecheck_response(%module{}, module), do: :ok

  defp typecheck_response(other, expected_module) do
    {:error, Error.new(:internal, "Expected #{inspect(expected_module)}, got #{inspect(other)}")}
  end

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

  defp rpc_method_name(conn, rpc_meta, action) do
    rpc_meta[:method_name] ||
      List.last(conn.path_info) ||
      action |> Atom.to_string() |> Macro.camelize()
  end

  defp log_debug(metadata, started_at, status) do
    duration_native = System.monotonic_time() - started_at
    duration_ms = :erlang.convert_time_unit(duration_native, :native, :microsecond) / 1000

    Logger.debug(
      "ConnectRPC #{metadata.service}/#{metadata.method} codec=#{metadata.codec} " <>
        "duration=#{format_ms(duration_ms)}ms status=#{status}"
    )
  end

  defp format_ms(value), do: :erlang.float_to_binary(value, decimals: 1)

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
    normalized_name = normalize_header_name!(name, kind, index)
    [{normalized_name, normalize_header_value!(normalized_name, value, kind, index)}]
  end

  defp normalize_metadata_entry!({name, values}, kind, index) when is_binary(name) and is_list(values) do
    normalized_name = normalize_header_name!(name, kind, index)

    Enum.with_index(values, fn value, value_index ->
      {normalized_name, normalize_header_value!(normalized_name, value, kind, {index, value_index})}
    end)
  end

  defp normalize_metadata_entry!(%{} = entry, kind, index) do
    name = metadata_entry_name(entry, kind, index)
    values = metadata_entry_values(entry, kind, index)
    normalized_name = normalize_header_name!(name, kind, index)

    Enum.with_index(values, fn value, value_index ->
      {normalized_name, normalize_header_value!(normalized_name, value, kind, {index, value_index})}
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

      String.starts_with?(normalized_name, "connect-") ->
        raise ArgumentError,
              "Invalid #{kind} header name #{inspect(name)} at #{format_metadata_index(index)}. " <>
                "Header names beginning with \"connect-\" are reserved by Connect."

      Regex.match?(@metadata_name_regex, normalized_name) ->
        normalized_name

      true ->
        raise ArgumentError,
              "Invalid #{kind} header name #{inspect(name)} at #{format_metadata_index(index)}. " <>
                "Header names must match [0-9a-z_.-]."
    end
  end

  defp normalize_header_value!(name, value, kind, index) do
    normalized_value = to_string(value)

    if String.ends_with?(name, "-bin") do
      normalize_binary_header_value!(normalized_value, kind, index)
    else
      normalize_ascii_header_value!(normalized_value, kind, index)
    end
  end

  defp normalize_ascii_header_value!(value, kind, index) do
    if Regex.match?(@ascii_metadata_value_regex, value) do
      value
    else
      raise ArgumentError,
            "Invalid #{kind} header value at #{format_metadata_index(index)}. " <>
              "Non-binary metadata values must use printable ASCII characters."
    end
  end

  defp normalize_binary_header_value!(value, kind, index) do
    case decode_base64(value) do
      {:ok, decoded} ->
        Base.encode64(decoded, padding: false)

      :error ->
        raise ArgumentError,
              "Invalid #{kind} binary header value at #{format_metadata_index(index)}. " <>
                "Binary metadata values must be base64 (padded or unpadded)."
    end
  end

  defp decode_base64(value) do
    case Base.decode64(value) do
      {:ok, decoded} ->
        {:ok, decoded}

      :error ->
        Base.decode64(value, padding: false)
    end
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
    Enum.reduce(trailers, conn, fn {name, value}, acc_conn ->
      append_resp_header(acc_conn, trailer_header_name(name), value)
    end)
  end

  defp apply_response_headers(conn, []), do: conn

  defp apply_response_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {name, value}, acc_conn ->
      append_resp_header(acc_conn, name, value)
    end)
  end

  defp append_resp_header(conn, name, value) do
    %{conn | resp_headers: conn.resp_headers ++ [{name, value}]}
  end

  defp trailer_header_name("trailer-" <> _rest = name), do: name
  defp trailer_header_name(name), do: "trailer-" <> name
end
