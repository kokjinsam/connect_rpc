defmodule ConnectRPC.Plug.Context do
  @moduledoc false

  @behaviour Plug

  alias ConnectRPC.Context

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case conn.private[:connect_rpc_context] do
      %Context{} ->
        conn

      _ ->
        Plug.Conn.put_private(conn, :connect_rpc_context, Context.new())
    end
  end
end
