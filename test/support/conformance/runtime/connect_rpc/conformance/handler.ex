defmodule ConnectRPC.Conformance.Handler do
  @moduledoc false

  use ConnectRPC.Handler, service: ConnectRPC.Conformance.Service

  alias Connectrpc.Conformance.V1
  alias Connectrpc.Conformance.V1.ConformancePayload
  alias Google.Protobuf.Any

  @spec unary(V1.UnaryRequest.t(), Plug.Conn.t()) ::
          {:ok, V1.UnaryResponse.t(), keyword()}
          | {:error, ConnectRPC.Error.t(), keyword()}
  def unary(%V1.UnaryRequest{} = request, conn) do
    request_info = build_request_info(conn, [pack_any(request)])

    response_definition = request.response_definition
    response_metadata = response_metadata(response_definition)
    delay_ms = response_delay_ms(response_definition)

    result =
      case response_choice(response_definition) do
        {:error, %V1.Error{} = requested_error} ->
          connect_error = to_connect_error(requested_error, request_info)
          {:error, connect_error, response_metadata}

        {:response_data, data} ->
          response = %V1.UnaryResponse{
            payload: %ConformancePayload{
              request_info: request_info,
              data: data
            }
          }

          {:ok, response, response_metadata}

        :none ->
          response = %V1.UnaryResponse{payload: %ConformancePayload{request_info: request_info}}
          {:ok, response, response_metadata}
      end

    maybe_sleep(delay_ms)
    result
  end

  defp response_choice(nil), do: :none
  defp response_choice(%{response: nil}), do: :none
  defp response_choice(%{response: response}), do: response

  defp response_metadata(nil), do: %{response_headers: [], response_trailers: []}

  defp response_metadata(%{response_headers: headers, response_trailers: trailers}) do
    %{
      response_headers: normalize_metadata_entries(headers),
      response_trailers: normalize_metadata_entries(trailers)
    }
  end

  defp response_metadata(%{response_headers: headers}) do
    %{
      response_headers: normalize_metadata_entries(headers),
      response_trailers: []
    }
  end

  defp response_metadata(_), do: %{response_headers: [], response_trailers: []}

  defp normalize_metadata_entries(entries) when is_list(entries), do: entries
  defp normalize_metadata_entries(_entries), do: []

  defp response_delay_ms(nil), do: 0

  defp response_delay_ms(%{response_delay_ms: response_delay_ms}) when is_integer(response_delay_ms) do
    response_delay_ms
  end

  defp response_delay_ms(_), do: 0

  defp maybe_sleep(delay_ms) when is_integer(delay_ms) and delay_ms > 0 do
    Process.sleep(delay_ms)
  end

  defp maybe_sleep(_delay_ms), do: :ok

  defp to_connect_error(%V1.Error{} = requested_error, request_info) do
    details =
      requested_error.details
      |> Enum.map(&any_to_detail/1)
      |> Kernel.++([request_info])

    ConnectRPC.Error.new(
      code_from_proto(requested_error.code),
      requested_error.message || "",
      details
    )
  end

  defp any_to_detail(%Any{} = detail) do
    %{
      type: strip_any_prefix(detail.type_url),
      value: detail.value
    }
  end

  defp strip_any_prefix("type.googleapis.com/" <> type), do: type
  defp strip_any_prefix(type), do: type

  defp code_from_proto(:CODE_CANCELED), do: :canceled
  defp code_from_proto(:CODE_UNKNOWN), do: :unknown
  defp code_from_proto(:CODE_INVALID_ARGUMENT), do: :invalid_argument
  defp code_from_proto(:CODE_DEADLINE_EXCEEDED), do: :deadline_exceeded
  defp code_from_proto(:CODE_NOT_FOUND), do: :not_found
  defp code_from_proto(:CODE_ALREADY_EXISTS), do: :already_exists
  defp code_from_proto(:CODE_PERMISSION_DENIED), do: :permission_denied
  defp code_from_proto(:CODE_RESOURCE_EXHAUSTED), do: :resource_exhausted
  defp code_from_proto(:CODE_FAILED_PRECONDITION), do: :failed_precondition
  defp code_from_proto(:CODE_ABORTED), do: :aborted
  defp code_from_proto(:CODE_OUT_OF_RANGE), do: :out_of_range
  defp code_from_proto(:CODE_UNIMPLEMENTED), do: :unimplemented
  defp code_from_proto(:CODE_INTERNAL), do: :internal
  defp code_from_proto(:CODE_UNAVAILABLE), do: :unavailable
  defp code_from_proto(:CODE_DATA_LOSS), do: :data_loss
  defp code_from_proto(:CODE_UNAUTHENTICATED), do: :unauthenticated
  defp code_from_proto(_), do: :unknown

  defp build_request_info(conn, requests) do
    %ConformancePayload.RequestInfo{
      request_headers: grouped_headers(conn.req_headers),
      timeout_ms: parse_timeout(conn),
      requests: requests
    }
  end

  defp grouped_headers(headers) do
    headers
    |> Enum.group_by(fn {name, _value} -> name end, fn {_name, value} -> value end)
    |> Enum.map(fn {name, values} ->
      %V1.Header{name: name, value: values}
    end)
  end

  defp parse_timeout(conn) do
    case Plug.Conn.get_req_header(conn, "connect-timeout-ms") do
      [value | _rest] ->
        case Integer.parse(value) do
          {timeout_ms, ""} -> timeout_ms
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp pack_any(%module{} = message) do
    %Any{
      type_url: "type.googleapis.com/" <> module.full_name(),
      value: module.encode(message)
    }
  end
end
