defmodule ConnectRPCTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  test "handles unary JSON request/response" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json"]

    assert {:ok, %EchoResponse{message: "hello"}} =
             Protobuf.JSON.decode(conn.resp_body, EchoResponse)
  end

  test "handles unary protobuf request/response" do
    body = EchoRequest.encode(%EchoRequest{message: "hello"})

    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", body, [
        {"content-type", "application/proto"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/proto"]
    assert %EchoResponse{message: "hello"} = EchoResponse.decode(conn.resp_body)
  end

  test "returns 405 when request method is not POST" do
    conn =
      call_router(:get, "/connectrpc.test.v1.EchoService/Echo", "", [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 405
    assert get_resp_header(conn, "allow") == ["POST"]
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "returns unknown when content-type is unsupported" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", "hello", [
        {"content-type", "text/plain"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 415
    assert get_resp_header(conn, "content-type") == ["application/json"]
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "checks content-type before connect-protocol-version" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", "hello", [
        {"content-type", "text/plain"}
      ])

    assert conn.status == 415
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "returns invalid_argument when protocol header is missing for supported content-type" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"}
      ])

    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "returns unimplemented when compression is requested" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"},
        {"content-encoding", "gzip"}
      ])

    assert conn.status == 501
    assert %{"code" => "unimplemented"} = Jason.decode!(conn.resp_body)
  end

  test "returns router-level 404 for unknown method" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/DoesNotExist", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 404
  end

  test "maps decode failures to invalid_argument" do
    conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", ~s({"message":), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "does not invoke handler when decoding fails" do
    conn =
      call_router(:post, "/connectrpc.test.v1.NotifyService/Echo", ~s({"message":), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 400
    refute_received {:handler_invoked, _}
  end

  test "returns handled ConnectRPC error tuple from handler" do
    conn =
      call_router(:post, "/connectrpc.test.v1.FailService/Fail", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 400

    assert %{"code" => "invalid_argument", "message" => "name is required"} =
             Jason.decode!(conn.resp_body)
  end

  test "returns raised ConnectRPC error from handler" do
    conn =
      call_router(:post, "/connectrpc.test.v1.RaiseService/Fail", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 404
    assert %{"code" => "not_found", "message" => "user not found"} = Jason.decode!(conn.resp_body)
  end

  test "applies response metadata aliases on success" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataSuccessService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert get_resp_header(conn, "x-meta-map") == ["one", "two"]
    assert get_resp_header(conn, "x-meta-tuple") == ["tuple-value"]
    assert get_resp_header(conn, "trailer-x-meta-trailer") == ["trailer-value"]
  end

  test "applies metadata aliases on error" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataErrorService/Fail", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 400
    assert %{"code" => "invalid_argument", "message" => "metadata failure"} = Jason.decode!(conn.resp_body)

    assert get_resp_header(conn, "x-error-meta") == ["left", "right"]
    assert get_resp_header(conn, "trailer-x-error-trailer") == ["trailer-value"]
  end

  test "returns internal when response metadata contains invalid header entries" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataInvalidService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "returns internal when response metadata uses reserved connect- header names" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataReservedService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "returns internal when non-binary metadata values are not printable ASCII" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataAsciiInvalidService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "normalizes binary metadata values to unpadded base64" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataBinaryService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert get_resp_header(conn, "x-meta-bytes-bin") == ["AQI"]
    assert get_resp_header(conn, "trailer-x-meta-trailer-bytes-bin") == ["AQI"]
  end

  test "returns internal when binary metadata values are not base64" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MetadataBinaryInvalidService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "falls back to internal error when error detail encoding fails" do
    conn =
      call_router(:post, "/connectrpc.test.v1.BadDetailService/Fail", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "returns sanitized internal error by default for unexpected exceptions" do
    conn =
      call_router(:post, "/connectrpc.test.v1.CrashService/Boom", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => "internal error"} = Jason.decode!(conn.resp_body)
  end

  test "returns raw exception message when debug_exceptions is enabled" do
    conn =
      call_router(:post, "/connectrpc.test.v1.DebugCrashService/Boom", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => message} = Jason.decode!(conn.resp_body)
    assert message =~ "boom"
  end

  test "returns internal when handler returns wrong response type" do
    conn =
      call_router(:post, "/connectrpc.test.v1.MismatchService/Mismatch", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 500
    assert %{"code" => "internal", "message" => message} = Jason.decode!(conn.resp_body)
    assert message =~ "Expected ConnectRPC.TestProto.EchoResponse"
  end

  test "handler receives context with empty assigns by default" do
    conn =
      call_router(:post, "/connectrpc.test.v1.ContextService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert_received {:handler_context, %ConnectRPC.Context{assigns: %{}}}
  end

  test "ConnectRPC.Context.put/3 from upstream plug populates handler context" do
    conn =
      call_router(:post, "/connectrpc.test.v1.ContextAssignedService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert conn.status == 200
    assert_received {:handler_context, %ConnectRPC.Context{assigns: %{upstream_value: "from-upstream"}}}
  end

  test "emits telemetry start and stop events on success" do
    attach_telemetry()

    _conn =
      call_router(:post, "/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

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
      call_router(:post, "/connectrpc.test.v1.CrashService/Boom", ~s({"message":"hello"}), [
        {"content-type", "application/json"},
        {"connect-protocol-version", "1"}
      ])

    assert_receive {:telemetry, [:connect_rpc, :handler, :exception], measurements, metadata}
    assert measurements[:duration]
    assert metadata[:method] == "Boom"
    assert metadata[:kind] == :error
  end

  defp call_router(method, path, body, headers) do
    conn = conn(method, path, body)
    conn = Enum.reduce(headers, conn, fn {k, v}, c -> put_req_header(c, k, v) end)

    try do
      ConnectRPC.TestEndpoint.call(conn, ConnectRPC.TestEndpoint.init([]))
    rescue
      Phoenix.Router.NoRouteError ->
        send_resp(conn, 404, "")
    end
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
