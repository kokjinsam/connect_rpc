defmodule Connect.PlugTest do
  use ExUnit.Case, async: true

  # --- Test protobuf message modules ---

  defmodule TestRequest do
    use Protobuf, syntax: :proto3
    field(:name, 1, type: :string)
  end

  defmodule TestResponse do
    use Protobuf, syntax: :proto3
    field(:greeting, 1, type: :string)
  end

  # --- Test service ---

  defmodule TestService do
    use Connect.Service

    rpc(:Greet, Connect.PlugTest.TestRequest, Connect.PlugTest.TestResponse)
    rpc(:GreetError, Connect.PlugTest.TestRequest, Connect.PlugTest.TestResponse)

    rpc(:StreamGreet, Connect.PlugTest.TestRequest, Connect.PlugTest.TestResponse,
      stream: :response
    )
  end

  # --- Test implementation ---

  defmodule TestImpl do
    def greet(request, _stream) do
      %Connect.PlugTest.TestResponse{greeting: "Hello #{request.name}"}
    end

    def greet_error(_request, _stream) do
      Connect.Error.new("not_found", "User not found")
    end

    def stream_greet(request, stream) do
      {:ok, stream} =
        Connect.Stream.send(stream, %Connect.PlugTest.TestResponse{
          greeting: "Hi #{request.name}"
        })

      stream
    end
  end

  # --- Plug init ---

  @plug_opts Connect.Plug.init(
               service: TestService,
               impl: TestImpl,
               require_version: true
             )

  @plug_opts_no_version Connect.Plug.init(
                          service: TestService,
                          impl: TestImpl,
                          require_version: false
                        )

  defp call_plug(conn, opts \\ @plug_opts) do
    Connect.Plug.call(conn, opts)
  end

  defp valid_headers(conn) do
    conn
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("connect-protocol-version", "1")
  end

  # ===== Phase 1: Protocol Primitives =====

  describe "POST enforcement" do
    test "GET returns 405" do
      conn =
        Plug.Test.conn(:get, "/Greet")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 405
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "unimplemented"
    end

    test "PUT returns 405" do
      conn =
        Plug.Test.conn(:put, "/Greet")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 405
    end
  end

  describe "Connect-Protocol-Version enforcement" do
    test "missing version returns 400 when required" do
      conn =
        Plug.Test.conn(:post, "/Greet", "{}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> call_plug()

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "invalid_argument"
    end

    test "missing version is accepted when not required" do
      body = Protobuf.JSON.encode!(%TestRequest{name: "world"})

      conn =
        Plug.Test.conn(:post, "/Greet", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> call_plug(@plug_opts_no_version)

      assert conn.status == 200
    end

    test "version 1 is accepted" do
      body = Protobuf.JSON.encode!(%TestRequest{name: "world"})

      conn =
        Plug.Test.conn(:post, "/Greet", body)
        |> valid_headers()
        |> call_plug()

      assert conn.status == 200
    end

    test "wrong version returns 400" do
      conn =
        Plug.Test.conn(:post, "/Greet", "{}")
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_req_header("connect-protocol-version", "2")
        |> call_plug()

      assert conn.status == 400
    end
  end

  describe "content-type validation" do
    test "streaming content-type with charset is rejected" do
      conn =
        Plug.Test.conn(:post, "/StreamGreet", "")
        |> Plug.Conn.put_req_header("content-type", "application/connect+json; charset=utf-8")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 415
    end

    test "unknown content-type returns 415" do
      conn =
        Plug.Test.conn(:post, "/Greet", "")
        |> Plug.Conn.put_req_header("content-type", "text/plain")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 415
    end
  end

  # ===== Phase 2: Error Model =====

  describe "handler returning Connect.Error" do
    test "unary handler returning error sends proper error response" do
      body = Protobuf.JSON.encode!(%TestRequest{name: "ghost"})

      conn =
        Plug.Test.conn(:post, "/GreetError", body)
        |> valid_headers()
        |> call_plug()

      assert conn.status == 404
      resp = Jason.decode!(conn.resp_body)
      assert resp["code"] == "not_found"
      assert resp["message"] == "User not found"
    end
  end

  describe "error responses are always JSON" do
    test "unimplemented method returns JSON even for proto content-type" do
      body = Protobuf.encode(%TestRequest{name: "test"})

      conn =
        Plug.Test.conn(:post, "/NonExistent", body)
        |> Plug.Conn.put_req_header("content-type", "application/proto")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 501
      content_type = Plug.Conn.get_resp_header(conn, "content-type") |> List.first()
      assert String.contains?(content_type, "application/json")
    end
  end

  # ===== Unary happy path =====

  describe "unary RPC" do
    test "successful JSON request/response" do
      body = Protobuf.JSON.encode!(%TestRequest{name: "world"})

      conn =
        Plug.Test.conn(:post, "/Greet", body)
        |> valid_headers()
        |> call_plug()

      assert conn.status == 200
      content_type = Plug.Conn.get_resp_header(conn, "content-type") |> List.first()
      assert String.contains?(content_type, "application/json")
      resp = Protobuf.JSON.decode!(conn.resp_body, TestResponse)
      assert resp.greeting == "Hello world"
    end

    test "successful proto request/response" do
      body = Protobuf.encode(%TestRequest{name: "world"})

      conn =
        Plug.Test.conn(:post, "/Greet", body)
        |> Plug.Conn.put_req_header("content-type", "application/proto")
        |> Plug.Conn.put_req_header("connect-protocol-version", "1")
        |> call_plug()

      assert conn.status == 200
      resp = TestResponse.decode(conn.resp_body)
      assert resp.greeting == "Hello world"
    end

    test "malformed body returns invalid_argument" do
      conn =
        Plug.Test.conn(:post, "/Greet", "not valid json{{{")
        |> valid_headers()
        |> call_plug()

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "invalid_argument"
    end
  end

  describe "unknown method" do
    test "returns unimplemented with 501" do
      conn =
        Plug.Test.conn(:post, "/NonExistent", "{}")
        |> valid_headers()
        |> call_plug()

      assert conn.status == 501
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "unimplemented"
    end
  end
end
