defmodule ConnectRPCTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.TestHandlers
  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  test "handles unary JSON request/response" do
    conn =
      :post
      |> conn("/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json"]

    assert {:ok, %EchoResponse{message: "hello"}} =
             Protobuf.JSON.decode(conn.resp_body, EchoResponse)
  end

  test "handles unary protobuf request/response" do
    body = EchoRequest.encode(%EchoRequest{message: "hello"})

    conn =
      :post
      |> conn("/Echo", body)
      |> put_req_header("content-type", "application/proto")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/proto"]
    assert %EchoResponse{message: "hello"} = EchoResponse.decode(conn.resp_body)
  end

  test "returns 405 when request method is not POST" do
    conn =
      :get
      |> conn("/Echo", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 405
    assert get_resp_header(conn, "allow") == ["POST"]
    assert %{"code" => "unimplemented"} = Jason.decode!(conn.resp_body)
  end

  test "returns invalid_argument when protocol header is missing" do
    conn =
      :post
      |> conn("/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "returns invalid_argument when content-type is unsupported" do
    conn =
      :post
      |> conn("/Echo", "hello")
      |> put_req_header("content-type", "text/plain")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 415
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "returns unimplemented when compression is requested" do
    conn =
      :post
      |> conn("/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> put_req_header("content-encoding", "gzip")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 501
    assert %{"code" => "unimplemented"} = Jason.decode!(conn.resp_body)
  end

  test "returns unimplemented for unknown method" do
    conn =
      :post
      |> conn("/DoesNotExist", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 501

    assert %{"code" => "unimplemented", "message" => message} = Jason.decode!(conn.resp_body)
    assert message =~ "Method DoesNotExist"
  end

  test "maps read_body :too_large to resource_exhausted" do
    conn =
      :post
      |> conn("/Echo", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler,
        read_body_fun: fn _conn, _opts -> {:error, :too_large} end
      )

    assert conn.status == 413
    assert %{"code" => "resource_exhausted"} = Jason.decode!(conn.resp_body)
  end

  test "maps read_body :timeout to deadline_exceeded" do
    conn =
      :post
      |> conn("/Echo", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler,
        read_body_fun: fn _conn, _opts -> {:error, :timeout} end
      )

    assert conn.status == 504
    assert %{"code" => "deadline_exceeded"} = Jason.decode!(conn.resp_body)
  end

  test "maps other body read errors to internal" do
    conn =
      :post
      |> conn("/Echo", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler,
        read_body_fun: fn _conn, _opts -> {:error, :closed} end
      )

    assert conn.status == 500
    assert %{"code" => "internal"} = Jason.decode!(conn.resp_body)
  end

  test "maps decode failures to invalid_argument" do
    conn =
      :post
      |> conn("/Echo", ~s({"message":))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "does not invoke handler when decoding fails" do
    conn =
      :post
      |> conn("/Echo", ~s({"message":))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.NotifyHandler)

    assert conn.status == 400
    refute_received {:handler_invoked, _}
  end

  test "returns handled ConnectRPC error tuple from handler" do
    conn =
      :post
      |> conn("/Fail", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.FailHandler)

    assert conn.status == 400

    assert %{"code" => "invalid_argument", "message" => "name is required"} =
             Jason.decode!(conn.resp_body)
  end

  test "returns raised ConnectRPC error from handler" do
    conn =
      :post
      |> conn("/Fail", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.RaiseConnectErrorHandler)

    assert conn.status == 404
    assert %{"code" => "not_found", "message" => "user not found"} = Jason.decode!(conn.resp_body)
  end

  test "returns sanitized internal error by default for unexpected exceptions" do
    conn =
      :post
      |> conn("/Boom", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.CrashHandler)

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "returns raw exception message when debug_exceptions is enabled" do
    conn =
      :post
      |> conn("/Boom", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.CrashHandler, debug_exceptions: true)

    assert conn.status == 500
    assert %{"code" => "internal", "message" => message} = Jason.decode!(conn.resp_body)
    assert message =~ "boom"
  end

  test "returns internal when handler returns wrong response type" do
    conn =
      :post
      |> conn("/Mismatch", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.MismatchHandler)

    assert conn.status == 500
    assert %{"code" => "internal", "message" => message} = Jason.decode!(conn.resp_body)
    assert message =~ "Expected ConnectRPC.TestProto.EchoResponse"
  end

  test "emits telemetry start and stop events on success" do
    attach_telemetry()

    _conn =
      :post
      |> conn("/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.EchoHandler)

    assert_receive {:telemetry, [:connect_rpc, :handler, :start], measurements, metadata}
    assert measurements[:system_time]
    assert metadata[:method] == "Echo"

    assert_receive {:telemetry, [:connect_rpc, :handler, :stop], stop_measurements, stop_metadata}
    assert stop_measurements[:duration]
    assert stop_metadata[:method] == "Echo"
  end

  test "emits telemetry exception event on crash" do
    attach_telemetry()

    _conn =
      :post
      |> conn("/Boom", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")
      |> call_rpc(TestHandlers.CrashHandler)

    assert_receive {:telemetry, [:connect_rpc, :handler, :exception], measurements, metadata}
    assert measurements[:duration]
    assert metadata[:method] == "Boom"
    assert metadata[:kind] == :error
  end

  defp call_rpc(conn, handler, opts \\ []) do
    init_opts = ConnectRPC.init([handler: handler] ++ opts)
    ConnectRPC.call(conn, init_opts)
  end

  defp attach_telemetry do
    name = "connect-rpc-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      name,
      [
        [:connect_rpc, :handler, :start],
        [:connect_rpc, :handler, :stop],
        [:connect_rpc, :handler, :exception]
      ],
      &__MODULE__.handle_telemetry/4,
      self()
    )

    on_exit(fn -> :telemetry.detach(name) end)
  end

  def handle_telemetry(event, measurements, metadata, pid) do
    send(pid, {:telemetry, event, measurements, metadata})
  end
end
