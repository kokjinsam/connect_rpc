defmodule GreeterExampleWeb.ConnectRPCTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  test "greets via ConnectRPC JSON endpoint" do
    conn =
      :post
      |> conn("/connectrpc.greet.v1.GreeterService/Greet", ~s({"name":"World"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn = GreeterExampleWeb.Router.call(conn, GreeterExampleWeb.Router.init([]))

    assert conn.status == 200
    assert %{"greeting" => "Hello, World!"} = Jason.decode!(conn.resp_body)
  end
end
