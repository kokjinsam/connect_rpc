defmodule ConnectRPC.Plug.DecoderTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.Plug.Decoder
  alias ConnectRPC.TestProto.EchoRequest

  test "decodes request and assigns connect_rpc_request" do
    conn =
      :post
      |> conn("/", ~s({"message":"hello"}))
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    conn = Decoder.call(conn, Decoder.init([]))

    refute conn.halted
    assert %EchoRequest{message: "hello"} = conn.assigns.connect_rpc_request
  end

  test "raises when body was already consumed" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})
      |> Map.put(:body_params, %{"message" => "hello"})

    assert_raise RuntimeError, ~r/Request body already consumed by an upstream parser/, fn ->
      Decoder.call(conn, Decoder.init([]))
    end
  end

  test "maps read_body too_large error" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    opts = Decoder.init(read_body_fun: fn _conn, _opts -> {:error, :too_large} end)
    conn = Decoder.call(conn, opts)

    assert conn.halted
    assert conn.status == 413
    assert %{"code" => "resource_exhausted"} = Jason.decode!(conn.resp_body)
  end

  test "maps read_body timeout error" do
    conn =
      :post
      |> conn("/", "")
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    opts = Decoder.init(read_body_fun: fn _conn, _opts -> {:error, :timeout} end)
    conn = Decoder.call(conn, opts)

    assert conn.halted
    assert conn.status == 504
    assert %{"code" => "deadline_exceeded"} = Jason.decode!(conn.resp_body)
  end

  test "maps decode errors to invalid_argument" do
    conn =
      :post
      |> conn("/", ~s({"message":))
      |> assign(:connect_rpc_codec, JSON)
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    conn = Decoder.call(conn, Decoder.init([]))

    assert conn.halted
    assert conn.status == 400
    assert %{"code" => "invalid_argument"} = Jason.decode!(conn.resp_body)
  end

  test "raises when codec was not assigned by upstream plug" do
    conn =
      :post
      |> conn("/", ~s({"message":"hello"}))
      |> put_private(:connect_rpc_rpc, %{request: EchoRequest})

    assert_raise RuntimeError,
                 ~r/No codec assigned\. Ensure ConnectRPC\.Plug\.Codec runs before ConnectRPC\.Plug\.Decoder\./,
                 fn ->
                   Decoder.call(conn, Decoder.init([]))
                 end
  end
end
