defmodule ConnectRPC.ParserTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.Parser
  alias ConnectRPC.TestProto.EchoRequest

  test "returns {:next, conn} when protocol header is missing" do
    conn =
      :post
      |> conn("/", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")

    assert {:next, conn} = Parser.parse(conn, "application", "json", %{}, Parser.init([]))
    refute Map.has_key?(conn.private, :connect_rpc_valid)
  end

  test "parses JSON body and assigns JSON codec" do
    conn =
      :post
      |> conn("/", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    assert {:ok, %{"message" => "hello"}, conn} =
             Parser.parse(conn, "application", "json", %{}, Parser.init([]))

    assert conn.assigns.connect_rpc_codec == ConnectRPC.Codec.JSON
    assert conn.private.connect_rpc_valid == true
    assert conn.private.connect_rpc_body_format == :json_map
  end

  test "parses proto body as raw binary" do
    body = EchoRequest.encode(%EchoRequest{message: "hello"})

    conn =
      :post
      |> conn("/", body)
      |> put_req_header("content-type", "application/proto")
      |> put_req_header("connect-protocol-version", "1")

    assert {:ok, %{"_raw" => ^body}, conn} =
             Parser.parse(conn, "application", "proto", %{}, Parser.init([]))

    assert conn.assigns.connect_rpc_codec == ConnectRPC.Codec.Proto
    assert conn.private.connect_rpc_valid == true
    assert conn.private.connect_rpc_body_format == :raw_binary
  end

  test "marks request invalid for malformed JSON without raising" do
    conn =
      :post
      |> conn("/", ~s({"message":))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    assert {:ok, %{}, conn} = Parser.parse(conn, "application", "json", %{}, Parser.init([]))

    assert conn.private.connect_rpc_valid == false
    assert [{error, 400}] = conn.private.connect_rpc_errors
    assert error.code == :invalid_argument
  end

  test "marks request invalid when method is not POST" do
    conn =
      :get
      |> conn("/", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    assert {:ok, %{}, conn} = Parser.parse(conn, "application", "json", %{}, Parser.init([]))

    assert conn.private.connect_rpc_valid == false
    assert [{error, 405}] = conn.private.connect_rpc_errors
    assert error.code == :unknown
  end

  test "returns {:error, :too_large, conn} when body exceeds parser length" do
    conn =
      :post
      |> conn("/", "too large")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    assert {:error, :too_large, _conn} =
             Parser.parse(conn, "application", "json", %{}, Parser.init(length: 1, read_length: 1))
  end

  test "raises when codec list is invalid" do
    assert_raise ArgumentError, ~r/Expected codec module/, fn ->
      Parser.init(codecs: [NoSuchCodecModule])
    end
  end
end
