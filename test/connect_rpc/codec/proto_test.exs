defmodule ConnectRPC.Codec.ProtoTest do
  use ExUnit.Case, async: true

  alias ConnectRPC.Codec.Proto
  alias ConnectRPC.TestProto.{EchoRequest, EchoResponse}

  test "encodes and decodes protobuf messages" do
    request = %EchoRequest{message: "hello"}

    assert {:ok, binary} = Proto.encode(request)
    assert is_binary(binary)
    assert {:ok, decoded} = Proto.decode(binary, EchoRequest)
    assert decoded == request
  end

  test "returns error tuple when decode fails" do
    assert {:error, _reason} = Proto.decode(<<255, 255>>, EchoRequest)
  end

  test "returns metadata helpers" do
    assert Proto.id() == :proto
    assert Proto.media_type() == "application/proto"
  end

  test "returns error tuple when encode fails for malformed struct" do
    malformed = %EchoResponse{message: 123}
    assert {:error, _reason} = Proto.encode(malformed)
  end
end
