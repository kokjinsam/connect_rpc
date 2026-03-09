defmodule ConnectRPC do
  @moduledoc """
  ConnectRPC-compatible server for Phoenix.

  ## Quick Start

      # 1. Generate Elixir modules from .proto via protobuf-elixir
      # 2. Define a handler:
      defmodule MyApp.GreetHandler do
        use ConnectRPC.Handler

        def say(conn, %SayRequest{} = request) do
          {:ok, %SayResponse{greeting: "Hello, \#{request.name}!"}}
        end
      end

      # 3. Add routes in your router:
      defmodule MyApp.Router do
        use Phoenix.Router
        use ConnectRPC.Router

        service "/connectrpc.greet.v1.GreetService", MyApp.GreetHandler do
          rpc "/Say", :say, request: SayRequest, response: SayResponse
        end
      end
  """
end
