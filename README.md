# ConnectRPC

`connect_rpc` is a ConnectRPC-compatible server Plug for Elixir/Phoenix.

## Scope

- Connect protocol
- Unary RPCs
- `application/proto` and `application/json`
- Connect-style JSON error responses

Out of scope for v0.1.0:

- Streaming (server/client/bidi)
- GET idempotent RPCs
- Connect-level compression

## Installation

Add to your dependencies:

```elixir
defp deps do
  [
    {:connect_rpc, "~> 0.1.0"}
  ]
end
```

## Define Messages and Service

Generate your protobuf modules with `protobuf-elixir`, then define a service metadata module and handler:

```elixir
defmodule MyApp.Proto.EchoRequest do
  use Protobuf, syntax: :proto3
  field :message, 1, type: :string
end

defmodule MyApp.Proto.EchoResponse do
  use Protobuf, syntax: :proto3
  field :message, 1, type: :string
end

defmodule MyApp.Proto.EchoService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.EchoService",
      methods: [
        %{name: "Echo", request: MyApp.Proto.EchoRequest, response: MyApp.Proto.EchoResponse}
      ]
    }
  end
end

defmodule MyApp.EchoHandler do
  use ConnectRPC.Handler, service: MyApp.Proto.EchoService

  def echo(%MyApp.Proto.EchoRequest{message: msg}, _conn) do
    {:ok, %MyApp.Proto.EchoResponse{message: msg}}
  end
end
```

## Mount in Phoenix Router

```elixir
defmodule MyApp.Router do
  use Phoenix.Router

  forward "/connectrpc.test.v1.EchoService",
    ConnectRPC,
    handler: MyApp.EchoHandler
end
```

## Request Example

```bash
curl -X POST http://localhost:4000/connectrpc.test.v1.EchoService/Echo \
  -H "Content-Type: application/json" \
  -H "Connect-Protocol-Version: 1" \
  -d '{"message":"hello"}'
```

## Telemetry

The plug emits:

- `[:connect_rpc, :handler, :start]`
- `[:connect_rpc, :handler, :stop]`
- `[:connect_rpc, :handler, :exception]`

## Conformance

Run ConnectRPC server conformance with:

```bash
./conformance/bin/run
```

This command downloads `connectconformance` (cached in `conformance/.cache/`), compiles with `MIX_ENV=test`, and runs in `--mode server` using:

- `conformance/config/server.yaml`
- `conformance/known-failing/server.txt`

## Example

- Greeter example app: `examples/greeter` (see [examples/greeter/README.md](examples/greeter/README.md))
