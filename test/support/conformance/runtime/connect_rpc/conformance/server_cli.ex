defmodule ConnectRPC.Conformance.ServerCLI do
  @moduledoc false

  alias ConnectRPC.Conformance.Server
  alias Connectrpc.Conformance.V1.{ServerCompatRequest, ServerCompatResponse}

  @max_request_size 1_048_576

  @spec main() :: no_return()
  def main do
    with :ok <- ensure_runtime_started(),
         {:ok, request} <- read_request(),
         {:ok, %{response: %ServerCompatResponse{} = response}} <- Server.start(request),
         :ok <- write_response(response) do
      Process.sleep(:infinity)
    else
      {:error, reason} ->
        IO.binwrite(
          :stderr,
          "connect_rpc conformance bootstrap failed: #{format_reason(reason)}\n"
        )

        System.halt(1)
    end
  end

  defp ensure_runtime_started do
    with {:ok, _apps} <- Application.ensure_all_started(:connect_rpc),
         {:ok, _apps} <- Application.ensure_all_started(:bandit) do
      :ok
    end
  end

  defp read_request do
    with {:ok, <<size::32-big-unsigned-integer>>} <- read_exact(4),
         :ok <- validate_request_size(size),
         {:ok, payload} <- read_exact(size),
         {:ok, request} <- decode_request(payload) do
      {:ok, request}
    end
  end

  defp validate_request_size(size) when size <= @max_request_size, do: :ok

  defp validate_request_size(size) do
    {:error, {:request_too_large, size, @max_request_size}}
  end

  defp decode_request(payload) do
    try do
      {:ok, ServerCompatRequest.decode(payload)}
    rescue
      exception -> {:error, {:invalid_request, exception}}
    end
  end

  defp read_exact(0), do: {:ok, <<>>}

  defp read_exact(bytes) when is_integer(bytes) and bytes > 0 do
    case IO.binread(:stdio, bytes) do
      :eof ->
        {:error, :unexpected_eof}

      {:error, reason} ->
        {:error, {:read_error, reason}}

      data when is_binary(data) and byte_size(data) == bytes ->
        {:ok, data}

      data when is_binary(data) ->
        {:error, {:unexpected_eof, byte_size(data), bytes}}
    end
  end

  defp write_response(%ServerCompatResponse{} = response) do
    try do
      payload = ServerCompatResponse.encode(response)
      frame = <<byte_size(payload)::32-big-unsigned-integer, payload::binary>>
      IO.binwrite(:stdio, frame)
    rescue
      exception -> {:error, {:write_error, exception}}
    end
  end

  defp format_reason({:invalid_request, exception}), do: Exception.message(exception)
  defp format_reason({:write_error, exception}), do: Exception.message(exception)
  defp format_reason({:request_too_large, size, max}), do: "request size #{size} exceeds #{max}"
  defp format_reason(reason), do: inspect(reason)
end
