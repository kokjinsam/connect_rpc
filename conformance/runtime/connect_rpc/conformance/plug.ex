defmodule ConnectRPC.Conformance.Plug do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @service_prefix "/connectrpc.conformance.v1.ConformanceService"

  @impl Plug
  def init(_opts) do
    %{
      service_prefix: @service_prefix,
      connect_opts: ConnectRPC.init(handler: ConnectRPC.Conformance.Handler)
    }
  end

  @impl Plug
  def call(conn, %{service_prefix: service_prefix, connect_opts: connect_opts}) do
    if String.starts_with?(conn.request_path, service_prefix) do
      method_path = String.replace_prefix(conn.request_path, service_prefix, "")
      request_path = if method_path == "", do: "/", else: method_path
      path_info = String.split(method_path, "/", trim: true)

      conn
      |> Map.put(:request_path, request_path)
      |> Map.put(:path_info, path_info)
      |> ConnectRPC.call(connect_opts)
    else
      send_resp(conn, 404, "")
    end
  end
end
