defmodule ConnectRPC.Plug.Validator do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  alias ConnectRPC.Protocol

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    with :ok <- Protocol.validate_post(conn),
         :ok <- Protocol.validate_protocol_version(conn),
         :ok <- Protocol.validate_compression(conn) do
      conn
    else
      {:error, error, status} ->
        conn
        |> maybe_put_allow_header(status)
        |> Protocol.send_error(error, status)
        |> halt()
    end
  end

  defp maybe_put_allow_header(conn, 405), do: put_resp_header(conn, "allow", "POST")
  defp maybe_put_allow_header(conn, _status), do: conn
end
