defmodule ConnectRPC.Plug.CodecTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.Plug.Codec
  alias ConnectRPC.TestCodecs.EchoText

  test "assigns negotiated codec" do
    conn =
      :post
      |> conn("/", "")
      |> put_req_header("content-type", "application/json")

    conn = Codec.call(conn, Codec.init([]))

    refute conn.halted
    assert conn.assigns.connect_rpc_codec == ConnectRPC.Codec.JSON
  end

  test "returns 415 for unsupported content type" do
    conn =
      :post
      |> conn("/", "")
      |> put_req_header("content-type", "text/plain")

    conn = Codec.call(conn, Codec.init([]))

    assert conn.halted
    assert conn.status == 415
    assert %{"code" => "unknown"} = Jason.decode!(conn.resp_body)
  end

  test "skips negotiation for non-POST requests" do
    conn =
      :get
      |> conn("/", "")
      |> put_req_header("content-type", "text/plain")

    conn = Codec.call(conn, Codec.init([]))

    refute conn.halted
    refute Map.has_key?(conn.assigns, :connect_rpc_codec)
  end

  test "supports custom codec list" do
    conn =
      :post
      |> conn("/", "")
      |> put_req_header("content-type", "application/x-echo-text")

    conn = Codec.call(conn, Codec.init(codecs: [EchoText]))

    refute conn.halted
    assert conn.assigns.connect_rpc_codec == EchoText
  end

  test "raises on invalid codec module" do
    assert_raise ArgumentError, ~r/Expected codec module/, fn ->
      Codec.init(codecs: [NoSuchCodecModule])
    end
  end
end
