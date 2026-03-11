defmodule ConnectRPC.Conformance.Plug.RequestInfo do
  @moduledoc false

  @behaviour Plug

  alias ConnectRPC.Context

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    timeout_ms = parse_timeout(conn)

    conn
    |> Context.put(:req_headers, conn.req_headers)
    |> Context.put(:timeout_ms, timeout_ms)
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
end
