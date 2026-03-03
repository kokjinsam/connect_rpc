defmodule GreeterExample.Router do
  @moduledoc false

  use Phoenix.Router
  Code.ensure_compiled!(GreeterExample.Handler)

  forward("/connectrpc.greet.v1.GreeterService", ConnectRPC, handler: GreeterExample.Handler)
end
