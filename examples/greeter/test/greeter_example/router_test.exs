defmodule GreeterExample.RouterTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  @endpoint GreeterExample.Endpoint

  test "responds to Say with greeting" do
    conn =
      conn(:post, "/connectrpc.greet.v1.GreeterService/Say", ~s({"name":"Sam"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> @endpoint.call([])

    assert conn.status == 200
    assert ["application/json"] == get_resp_header(conn, "content-type")

    assert %{"greeting" => "Hello, Sam!"} = Jason.decode!(conn.resp_body)
  end

  test "uses World fallback for blank names" do
    conn =
      conn(:post, "/connectrpc.greet.v1.GreeterService/Say", ~s({"name":"  "}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> @endpoint.call([])

    assert conn.status == 200
    assert %{"greeting" => "Hello, World!"} = Jason.decode!(conn.resp_body)
  end
end
