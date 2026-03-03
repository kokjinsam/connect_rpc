defmodule GreeterExample.Greet.V1.SayRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3

  field(:name, 1, type: :string)
end

defmodule GreeterExample.Greet.V1.SayResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3

  field(:greeting, 1, type: :string)
end

defmodule GreeterExample.Greet.V1.GreeterService do
  @moduledoc false

  @spec __connect_rpc_service__() :: map()
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.greet.v1.GreeterService",
      methods: [
        %{
          name: "Say",
          request: GreeterExample.Greet.V1.SayRequest,
          response: GreeterExample.Greet.V1.SayResponse
        }
      ]
    }
  end
end
