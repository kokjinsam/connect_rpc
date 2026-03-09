defmodule GreeterExample.Gen.GreetRequest do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:name, 1, type: :string)
end

defmodule GreeterExample.Gen.GreetResponse do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field(:greeting, 1, type: :string)
end
