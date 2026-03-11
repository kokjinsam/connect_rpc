defmodule ConnectRPC.Plug.HandlerTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.Codec.Proto
  alias ConnectRPC.Context
  alias ConnectRPC.Error
  alias ConnectRPC.Plug.Handler
  alias ConnectRPC.TestProto.EchoRequest

  test "sends connect error when parser marked request invalid" do
    conn =
      :get
      |> conn("/", "")
      |> put_private(:connect_rpc_valid, false)
      |> put_private(:connect_rpc_errors, [{Error.new(:unknown, "Only POST is supported"), 405}])

    conn = Handler.call(conn, Handler.init([]))

    assert conn.halted
    assert conn.status == 405
    assert get_resp_header(conn, "allow") == ["POST"]
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "raises when parser was not configured in endpoint" do
    conn =
      :post
      |> conn("/", ~s({"message":"hello"}))
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    assert_raise RuntimeError, ~r/Add ConnectRPC\.Parser to Plug\.Parsers in your endpoint\./, fn ->
      Handler.call(conn, Handler.init([]))
    end
  end

  test "casts JSON body params into protobuf struct" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_valid, true)
      |> put_private(:connect_rpc_body_format, :json_map)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})
      |> Map.put(:body_params, %{"message" => "hello"})

    conn = Handler.call(conn, Handler.init([]))

    refute conn.halted
    assert %EchoRequest{message: "hello"} = conn.assigns.connect_rpc_request
  end

  test "casts raw proto body into protobuf struct" do
    raw = EchoRequest.encode(%EchoRequest{message: "hello"})

    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, Proto)
      |> put_private(:connect_rpc_valid, true)
      |> put_private(:connect_rpc_body_format, :raw_binary)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})
      |> Map.put(:body_params, %{"_raw" => raw})

    conn = Handler.call(conn, Handler.init([]))

    refute conn.halted
    assert %EchoRequest{message: "hello"} = conn.assigns.connect_rpc_request
  end

  test "initializes context when missing" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_valid, true)
      |> put_private(:connect_rpc_body_format, :json_map)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})
      |> Map.put(:body_params, %{"message" => "hello"})

    conn = Handler.call(conn, Handler.init([]))

    assert %Context{} = conn.private.connect_rpc_context
  end

  test "sends invalid_argument on decode failure" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, Proto)
      |> put_private(:connect_rpc_valid, true)
      |> put_private(:connect_rpc_body_format, :raw_binary)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})
      |> Map.put(:body_params, %{"_raw" => <<255, 255, 255>>})

    conn = Handler.call(conn, Handler.init([]))

    assert conn.halted
    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end
end
