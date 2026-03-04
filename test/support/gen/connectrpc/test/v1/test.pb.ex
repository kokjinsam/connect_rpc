defmodule ConnectRPC.TestProto.EchoRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.test.v1.EchoRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:message, 1, type: :string)
end

defmodule ConnectRPC.TestProto.EchoResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.test.v1.EchoResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:message, 1, type: :string)
end

defmodule ConnectRPC.TestProto.Detail do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.test.v1.Detail",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field(:reason, 1, type: :string)
end
