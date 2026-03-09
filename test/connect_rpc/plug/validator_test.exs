defmodule ConnectRPC.Plug.ValidatorTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.Plug.Validator

  test "rejects non-POST requests with 405 and Allow header" do
    conn = conn(:get, "/", "")
    conn = Validator.call(conn, Validator.init([]))

    assert conn.halted
    assert conn.status == 405
    assert get_resp_header(conn, "allow") == ["POST"]
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "rejects missing protocol header" do
    conn = conn(:post, "/", "")
    conn = Validator.call(conn, Validator.init([]))

    assert conn.halted
    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "rejects unsupported compression" do
    conn =
      :post
      |> conn("/", "")
      |> put_req_header("connect-protocol-version", "1")
      |> put_req_header("content-encoding", "gzip")

    conn = Validator.call(conn, Validator.init([]))

    assert conn.halted
    assert conn.status == 501
    assert %{"code" => "unimplemented"} = Jason.decode!(conn.resp_body)
  end

  test "passes valid request through" do
    conn =
      :post
      |> conn("/", "")
      |> put_req_header("connect-protocol-version", "1")

    conn = Validator.call(conn, Validator.init([]))

    refute conn.halted
    assert conn.status == nil
  end
end
