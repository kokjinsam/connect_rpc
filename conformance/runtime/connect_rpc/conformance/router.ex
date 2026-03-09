defmodule ConnectRPC.Conformance.Router do
  @moduledoc false

  use Phoenix.Router
  use ConnectRPC.Router

  service "/connectrpc.conformance.v1.ConformanceService", ConnectRPC.Conformance.Handler do
    rpc("/Unary", :unary,
      request: Connectrpc.Conformance.V1.UnaryRequest,
      response: Connectrpc.Conformance.V1.UnaryResponse
    )
  end
end
