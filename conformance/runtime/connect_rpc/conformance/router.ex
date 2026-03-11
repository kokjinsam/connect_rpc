defmodule ConnectRPC.Conformance.Router do
  @moduledoc false

  use Phoenix.Router
  use ConnectRPC.Router

  pipeline :request_info do
    plug(ConnectRPC.Conformance.Plug.RequestInfo)
  end

  service "/connectrpc.conformance.v1.ConformanceService", ConnectRPC.Conformance.Handler do
    pipe_through(:request_info)

    rpc("/Unary", :unary,
      request: Connectrpc.Conformance.V1.UnaryRequest,
      response: Connectrpc.Conformance.V1.UnaryResponse
    )
  end
end
