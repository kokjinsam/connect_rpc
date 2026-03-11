defmodule ConnectRPC.HandlerTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.TestHandlers.EchoHandler

  test "use ConnectRPC.Handler defines Plug callbacks" do
    assert function_exported?(EchoHandler, :init, 1)
    assert function_exported?(EchoHandler, :call, 2)
  end

  test "init/1 returns action atom" do
    assert EchoHandler.init(:echo) == :echo
  end

  test "call/2 dispatches to handler action" do
    conn =
      :post
      |> conn("/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn = ConnectRPC.TestEndpoint.call(conn, ConnectRPC.TestEndpoint.init([]))

    assert conn.status == 200
    assert %{"message" => "hello"} = Jason.decode!(conn.resp_body)
  end
end
