defmodule ConnectRPC.Conformance.Server do
  @moduledoc false

  alias Connectrpc.Conformance.V1.ServerCompatRequest
  alias Connectrpc.Conformance.V1.ServerCompatResponse

  @type state :: %{
          server_pid: pid(),
          response: ServerCompatResponse.t()
        }

  @spec start(ServerCompatRequest.t()) :: {:ok, state()} | {:error, term()}
  def start(%ServerCompatRequest{} = request) do
    with :ok <- validate_protocol(request.protocol),
         :ok <- validate_http_version(request.http_version),
         :ok <- validate_tls(request.use_tls) do
      plug = {ConnectRPC.Conformance.Plug, []}

      case start_bandit(plug) do
        {:ok, server_pid} ->
          with {:ok, {address, port}} <- listener_info(server_pid) do
            response = %ServerCompatResponse{
              host: normalize_host(address),
              port: port,
              pem_cert: ""
            }

            {:ok, %{server_pid: server_pid, response: response}}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp validate_protocol(:PROTOCOL_UNSPECIFIED), do: :ok
  defp validate_protocol(:PROTOCOL_CONNECT), do: :ok
  defp validate_protocol(other), do: {:error, {:unsupported_protocol, other}}

  defp validate_http_version(:HTTP_VERSION_UNSPECIFIED), do: :ok
  defp validate_http_version(:HTTP_VERSION_1), do: :ok
  defp validate_http_version(other), do: {:error, {:unsupported_http_version, other}}

  defp validate_tls(false), do: :ok
  defp validate_tls(true), do: {:error, :tls_not_supported}

  defp start_bandit(plug) do
    if Code.ensure_loaded?(Bandit) do
      apply(Bandit, :start_link, [
        [
          plug: plug,
          scheme: :http,
          ip: {127, 0, 0, 1},
          port: 0,
          startup_log: false,
          http_2_options: [enabled: false]
        ]
      ])
    else
      {:error, :bandit_not_available}
    end
  end

  defp listener_info(server_pid) do
    if Code.ensure_loaded?(ThousandIsland) do
      apply(ThousandIsland, :listener_info, [server_pid])
    else
      {:error, :thousand_island_not_available}
    end
  end

  defp normalize_host({0, 0, 0, 0}), do: "127.0.0.1"
  defp normalize_host({127, 0, 0, 1}), do: "127.0.0.1"
  defp normalize_host(address) when is_tuple(address), do: to_string(:inet.ntoa(address))
  defp normalize_host(_address), do: "127.0.0.1"
end
