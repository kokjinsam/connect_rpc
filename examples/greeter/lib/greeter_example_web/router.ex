defmodule GreeterExampleWeb.Router do
  use GreeterExampleWeb, :router
  use ConnectRPC.Router

  service "/connectrpc.greet.v1.GreeterService", GreeterExample.GreeterHandler do
    rpc("/Greet", :greet,
      request: GreeterExample.Gen.GreetRequest,
      response: GreeterExample.Gen.GreetResponse
    )
  end
end
