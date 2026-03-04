defmodule ConnectRPC.ProtocolTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.Protocol

  defmodule CustomJSONCodec do
    @moduledoc false
    def media_type, do: "application/json"
    def encode(_struct), do: {:ok, "{}"}
    def decode(_payload, _module), do: {:error, :not_implemented}
  end

  defmodule DetailWithoutFullName do
    @moduledoc false
    defstruct [:reason]

    def encode(_detail), do: <<1, 2, 3>>
  end

  test "validate_post/1 accepts POST and rejects others" do
    assert :ok = Protocol.validate_post(conn(:post, "/", ""))

    assert {:error, error, 405} = Protocol.validate_post(conn(:get, "/", ""))
    assert error.code == :unknown
  end

  test "validate_protocol_version/1 requires version 1 header" do
    assert {:error, error, 400} = Protocol.validate_protocol_version(conn(:post, "/", ""))
    assert error.code == :invalid_argument

    conn = :post |> conn("/", "") |> Plug.Conn.put_req_header("connect-protocol-version", "1")
    assert :ok = Protocol.validate_protocol_version(conn)
  end

  test "negotiate_codec/1 accepts json/proto and rejects unsupported media type" do
    json_conn =
      :post |> conn("/", "") |> Plug.Conn.put_req_header("content-type", "application/json")

    assert {:ok, JSON} = Protocol.negotiate_codec(json_conn)

    proto_conn =
      :post
      |> conn("/", "")
      |> Plug.Conn.put_req_header("content-type", "application/proto; charset=utf-8")

    assert {:ok, ConnectRPC.Codec.Proto} = Protocol.negotiate_codec(proto_conn)

    bad_conn = :post |> conn("/", "") |> Plug.Conn.put_req_header("content-type", "text/plain")
    assert {:error, error, 415} = Protocol.negotiate_codec(bad_conn)
    assert error.code == :unknown
  end

  test "negotiate_codec/2 honors codec list order" do
    json_conn =
      :post |> conn("/", "") |> Plug.Conn.put_req_header("content-type", "application/json")

    assert {:ok, CustomJSONCodec} =
             Protocol.negotiate_codec(json_conn, [CustomJSONCodec, JSON])
  end

  test "validate_compression/1 rejects non-identity encoding" do
    assert :ok = Protocol.validate_compression(conn(:post, "/", ""))

    identity_conn =
      :post
      |> conn("/", "")
      |> Plug.Conn.put_req_header("content-encoding", "identity")

    assert :ok = Protocol.validate_compression(identity_conn)

    gzip_conn = :post |> conn("/", "") |> Plug.Conn.put_req_header("content-encoding", "gzip")
    assert {:error, error, 501} = Protocol.validate_compression(gzip_conn)
    assert error.code == :unimplemented
  end

  test "error_payload/1 includes detail serialization when present" do
    detail = %ConnectRPC.TestProto.Detail{reason: "required"}
    error = ConnectRPC.Error.new(:invalid_argument, "invalid", [detail])

    payload = Protocol.error_payload(error)

    assert payload["code"] == "invalid_argument"
    assert payload["message"] == "invalid"
    assert [%{"type" => type, "value" => value}] = payload["details"]
    assert type == "connectrpc.test.v1.Detail"
    assert is_binary(value)
    assert byte_size(value) > 0
    refute String.ends_with?(value, "=")
  end

  test "error_payload/1 raises when detail struct does not expose full_name/0" do
    detail = %DetailWithoutFullName{reason: "required"}
    error = ConnectRPC.Error.new(:invalid_argument, "invalid", [detail])

    assert_raise ArgumentError, ~r/does not expose full_name\/0/, fn ->
      Protocol.error_payload(error)
    end
  end
end
