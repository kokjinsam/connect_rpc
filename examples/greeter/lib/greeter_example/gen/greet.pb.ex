defmodule GreeterExample.Greet.V1.SayRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.greet.v1.SayRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :name, 1, type: :string
end

defmodule GreeterExample.Greet.V1.SayResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.greet.v1.SayResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  field :greeting, 1, type: :string
end
