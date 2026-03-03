defmodule ConnectRPC.Conformance.Service do
  @moduledoc false

  alias Connectrpc.Conformance.V1.UnaryRequest
  alias Connectrpc.Conformance.V1.UnaryResponse

  @spec __connect_rpc_service__() :: map()
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.conformance.v1.ConformanceService",
      methods: [
        %{
          name: "Unary",
          request: UnaryRequest,
          response: UnaryResponse
        }
      ]
    }
  end
end
