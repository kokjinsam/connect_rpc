defmodule ConnectRPC.Codec.JSONTest do
  use ExUnit.Case, async: true

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.TestProto.EchoRequest

  test "encodes and decodes protobuf messages as JSON" do
    request = %EchoRequest{message: "hello"}

    assert {:ok, body} = JSON.encode(request)
    assert is_binary(body)
    assert {:ok, decoded} = JSON.decode(body, EchoRequest)
    assert decoded == request
  end

  test "returns error tuple when decode fails" do
    assert {:error, _reason} = JSON.decode("{\"message\":", EchoRequest)
  end

  test "returns metadata helpers" do
    assert JSON.id() == :json
    assert JSON.media_type() == "application/json"
  end
end
