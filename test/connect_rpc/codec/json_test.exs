defmodule ConnectRPC.Codec.JSONTest do
  use ExUnit.Case, async: true

  alias ConnectRPC.Codec.JSON
  alias Connectrpc.Conformance.V1.ConformancePayload.RequestInfo
  alias Connectrpc.Conformance.V1.Error, as: ConformanceError
  alias Connectrpc.Conformance.V1.UnaryRequest
  alias Connectrpc.Conformance.V1.UnaryResponseDefinition
  alias ConnectRPC.TestProto.EchoRequest
  alias Google.Protobuf.BytesValue
  alias Google.Protobuf.Duration
  alias Google.Protobuf.Empty
  alias Google.Protobuf.Int64Value
  alias Google.Protobuf.Timestamp
  alias Google.Protobuf.UInt64Value

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

  test "returns media type" do
    assert JSON.media_type() == "application/json"
  end

  test "encodes json_name keys and omits unset proto3 defaults" do
    request = %UnaryRequest{request_data: <<1, 2, 3>>}

    assert {:ok, body} = JSON.encode(request)
    assert Jason.decode!(body) == %{"requestData" => "AQID"}
  end

  test "decodes both lowerCamelCase and proto field name variants" do
    assert {:ok, %UnaryRequest{request_data: <<1, 2, 3>>}} =
             JSON.decode(~s({"requestData":"AQID"}), UnaryRequest)

    assert {:ok, %UnaryRequest{request_data: <<1, 2, 3>>}} =
             JSON.decode(~s({"request_data":"AQID"}), UnaryRequest)
  end

  test "encodes and decodes oneof fields using flat JSON keys" do
    message = %UnaryResponseDefinition{response: {:response_data, <<1, 2, 3>>}}

    assert {:ok, body} = JSON.encode(message)
    assert Jason.decode!(body) == %{"responseData" => "AQID"}

    assert {:ok, %UnaryResponseDefinition{response: {:response_data, <<1, 2, 3>>}}} =
             JSON.decode(body, UnaryResponseDefinition)
  end

  test "encodes enums as names and decodes from names and integers" do
    message = %ConformanceError{code: :CODE_PERMISSION_DENIED}

    assert {:ok, body} = JSON.encode(message)
    assert Jason.decode!(body) == %{"code" => "CODE_PERMISSION_DENIED"}

    assert {:ok, %ConformanceError{code: :CODE_PERMISSION_DENIED}} =
             JSON.decode(~s({"code":"CODE_PERMISSION_DENIED"}), ConformanceError)

    assert {:ok, %ConformanceError{code: :CODE_PERMISSION_DENIED}} =
             JSON.decode(~s({"code":7}), ConformanceError)
  end

  test "encodes bytes as standard base64 and decodes url-safe base64" do
    request = %UnaryRequest{request_data: <<255, 238>>}

    assert {:ok, body} = JSON.encode(request)
    assert Jason.decode!(body) == %{"requestData" => "/+4="}

    assert {:ok, %UnaryRequest{request_data: <<255, 238>>}} =
             JSON.decode(~s({"requestData":"/+4="}), UnaryRequest)

    assert {:ok, %UnaryRequest{request_data: <<255, 238>>}} =
             JSON.decode(~s({"requestData":"_-4="}), UnaryRequest)

    assert {:ok, %UnaryRequest{request_data: <<255, 238>>}} =
             JSON.decode(~s({"requestData":"_-4"}), UnaryRequest)
  end

  test "encodes int64 fields as JSON strings and decodes strings or numbers" do
    timeout_ms = 9_007_199_254_740_993
    request_info = %RequestInfo{timeout_ms: timeout_ms}

    assert {:ok, body} = JSON.encode(request_info)
    assert Jason.decode!(body) == %{"timeoutMs" => Integer.to_string(timeout_ms)}

    assert {:ok, %RequestInfo{timeout_ms: ^timeout_ms}} =
             JSON.decode(~s({"timeoutMs":"9007199254740993"}), RequestInfo)

    assert {:ok, %RequestInfo{timeout_ms: ^timeout_ms}} =
             JSON.decode(~s({"timeoutMs":9007199254740993}), RequestInfo)
  end

  test "encodes and decodes core well-known types" do
    timestamp = %Timestamp{seconds: 1_700_000_000, nanos: 123_000_000}
    duration = %Duration{seconds: 1, nanos: 500_000_000}
    empty = %Empty{}
    bytes = %BytesValue{value: <<1, 2, 3>>}

    assert {:ok, ~s("2023-11-14T22:13:20.123Z")} = JSON.encode(timestamp)
    assert {:ok, ~s("1.500s")} = JSON.encode(duration)
    assert {:ok, "{}"} = JSON.encode(empty)
    assert {:ok, ~s("AQID")} = JSON.encode(bytes)

    assert {:ok, %Timestamp{seconds: 1_700_000_000, nanos: 123_000_000}} =
             JSON.decode(~s("2023-11-14T22:13:20.123Z"), Timestamp)

    assert {:ok, %Duration{seconds: 1, nanos: 500_000_000}} =
             JSON.decode(~s("1.500s"), Duration)

    assert {:ok, %Empty{}} = JSON.decode("{}", Empty)
    assert {:ok, %BytesValue{value: <<1, 2, 3>>}} = JSON.decode(~s("AQID"), BytesValue)
  end

  test "encodes int64 and uint64 wrappers as numbers and decodes strings or numbers" do
    assert {:ok, "42"} = JSON.encode(%Int64Value{value: 42})
    assert {:ok, "42"} = JSON.encode(%UInt64Value{value: 42})

    assert {:ok, %Int64Value{value: 42}} =
             JSON.decode(~s("42"), Int64Value)

    assert {:ok, %Int64Value{value: 42}} =
             JSON.decode("42", Int64Value)

    assert {:ok, %UInt64Value{value: 42}} =
             JSON.decode(~s("42"), UInt64Value)

    assert {:ok, %UInt64Value{value: 42}} =
             JSON.decode("42", UInt64Value)
  end
end
