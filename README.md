# ConnectRPC

ConnectRPC-compatible server for Elixir, implemented as a [Plug](https://github.com/elixir-plug/plug).

Works with [Phoenix.Router](https://hexdocs.pm/phoenix/Phoenix.Router.html), [Plug.Router](https://hexdocs.pm/plug/Plug.Router.html), or any Plug-compatible pipeline. Runs under Bandit or Cowboy.

v0.1.0 supports **unary RPCs** with the **Connect protocol**. Streaming, gRPC, and gRPC-Web are planned for future releases.

## Installation

Add `connect_rpc` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:connect_rpc, "~> 0.1.0"}
  ]
end
```

Requires `protobuf` ~> 0.15 for `full_name/0` support on error detail structs.

## Quick Start

### 1. Define protobuf messages and service

Generate Elixir modules from `.proto` files using [protobuf-elixir](https://github.com/elixir-protobuf/protobuf), or define them manually:

```elixir
defmodule MyApp.Greet.V1.SayRequest do
  use Protobuf, syntax: :proto3
  field :name, 1, type: :string
end

defmodule MyApp.Greet.V1.SayResponse do
  use Protobuf, syntax: :proto3
  field :greeting, 1, type: :string
end

defmodule MyApp.Greet.V1.GreeterService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.greet.v1.GreeterService",
      methods: [
        %{
          name: "Say",
          request: MyApp.Greet.V1.SayRequest,
          response: MyApp.Greet.V1.SayResponse
        }
      ]
    }
  end
end
```

### 2. Implement a handler

Each RPC method maps to a snake_case function in the handler:

```elixir
defmodule MyApp.GreeterHandler do
  use ConnectRPC.Handler, service: MyApp.Greet.V1.GreeterService

  def say(%MyApp.Greet.V1.SayRequest{name: name}, _conn) do
    {:ok, %MyApp.Greet.V1.SayResponse{greeting: "Hello, #{name}!"}}
  end
end
```

### 3. Mount in your router

**Phoenix:**

```elixir
defmodule MyApp.Router do
  use Phoenix.Router

  forward "/connectrpc.greet.v1.GreeterService",
    ConnectRPC,
    handler: MyApp.GreeterHandler
end
```

**Plug.Router:**

```elixir
defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/connectrpc.greet.v1.GreeterService",
    to: ConnectRPC,
    init_opts: [handler: MyApp.GreeterHandler]
end
```

### 4. Make a request

```bash
curl -X POST http://localhost:4000/connectrpc.greet.v1.GreeterService/Say \
  -H "Content-Type: application/json" \
  -H "Connect-Protocol-Version: 1" \
  -d '{"name": "World"}'

# {"greeting":"Hello, World!"}
```

## Handler Return Values

Handlers receive the decoded request struct and the `Plug.Conn`, and must return one of:

- `{:ok, response_struct}` - success
- `{:ok, response_struct, metadata}` - success with response headers/trailers
- `{:error, %ConnectRPC.Error{}}` - Connect error
- `{:error, %ConnectRPC.Error{}, metadata}` - Connect error with response headers/trailers
- `raise ConnectRPC.Error, code: :not_found, message: "..."` - raised Connect error

## Error Handling

Return or raise `ConnectRPC.Error` to send Connect error responses:

```elixir
def say(request, _conn) do
  case find_user(request.name) do
    nil ->
      {:error, ConnectRPC.Error.new(:not_found, "user not found")}

    user ->
      {:ok, %SayResponse{greeting: "Hello, #{user.name}!"}}
  end
end
```

Unexpected exceptions are caught and returned as `internal` errors with a sanitized message. Full details are logged and emitted via telemetry.

Enable `debug_exceptions: true` for development to include exception messages in the response:

```elixir
forward "/connectrpc.greet.v1.GreeterService",
  ConnectRPC,
  handler: MyApp.GreeterHandler,
  debug_exceptions: true
```

## Custom Codecs

Built-in codecs: `ConnectRPC.Codec.JSON` (`application/json`) and `ConnectRPC.Codec.Proto` (`application/proto`).

Implement `ConnectRPC.Codec` for custom serialization:

```elixir
defmodule MyApp.CustomCodec do
  @behaviour ConnectRPC.Codec

  @impl true
  def media_type, do: "application/x-custom"

  @impl true
  def decode(payload, module), do: {:ok, deserialize(payload, module)}

  @impl true
  def encode(struct), do: {:ok, serialize(struct)}
end
```

Register via `:codecs`. This **replaces** the default codecs entirely, so include the built-ins if you still need them:

```elixir
forward "/connectrpc.greet.v1.GreeterService",
  ConnectRPC,
  handler: MyApp.GreeterHandler,
  codecs: [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON, MyApp.CustomCodec]
```

## Body Size Limits

Configure via `:read_body_opts`, passed to `Plug.Conn.read_body/2`:

```elixir
forward "/connectrpc.greet.v1.GreeterService",
  ConnectRPC,
  handler: MyApp.GreeterHandler,
  read_body_opts: [length: 1_000_000]
```

## Response Metadata (Experimental)

Handlers may return response headers and trailers via a third element:

```elixir
def say(request, _conn) do
  metadata = %{
    response_headers: [{"x-request-id", "abc123"}],
    response_trailers: [{"x-checksum", "deadbeef"}]
  }

  {:ok, %SayResponse{greeting: "Hello!"}, metadata}
end
```

Trailers are sent as `trailer-<name>` response headers for unary RPCs.

## Plug.Parsers Compatibility

ConnectRPC reads the request body directly. If `Plug.Parsers` runs upstream and consumes the body, a clear error is raised.

**Option 1 — Exclude ConnectRPC content types** using the `:pass` option:

```elixir
plug Plug.Parsers,
  parsers: [:json],
  pass: ["application/proto", "application/json"],
  json_decoder: Jason
```

Note: passing `"application/json"` means `Plug.Parsers` won't parse JSON for *any* route. This works if ConnectRPC is your only JSON consumer.

**Option 2 (recommended) — Separate pipelines** so ConnectRPC routes bypass `Plug.Parsers` entirely:

```elixir
# In your Phoenix router
pipeline :api do
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
end

pipeline :rpc do
  # No Plug.Parsers — ConnectRPC handles body reading
end

scope "/" do
  pipe_through :rpc
  forward "/connectrpc.greet.v1.GreeterService", ConnectRPC, handler: MyApp.GreeterHandler
end

scope "/api" do
  pipe_through :api
  # REST routes here
end
```

## Telemetry

Three events following Phoenix conventions:

| Event                                  | Measurements                | When                      |
| -------------------------------------- | --------------------------- | ------------------------- |
| `[:connect_rpc, :handler, :start]`     | `%{system_time: integer()}` | Before handler invocation |
| `[:connect_rpc, :handler, :stop]`      | `%{duration: integer()}`    | After successful handling |
| `[:connect_rpc, :handler, :exception]` | `%{duration: integer()}`    | After handler exception   |

All events include metadata: `%{service: String.t(), method: String.t(), codec: String.t(), path: String.t()}`.

## Scope

**Supported in v0.1.0:**

- Connect protocol (unary RPCs)
- `application/proto` and `application/json` content types
- Connect-style JSON error responses
- Custom codec registration
- Compile-time handler validation
- Telemetry events

**Out of scope for v0.1.0:**

- Streaming (server/client/bidi)
- GET for idempotent RPCs
- Connect-level compression
- gRPC / gRPC-Web protocols

Streaming RPCs are compile-time recognized but not dispatched. Requests to streaming methods return `unimplemented` (HTTP 501).

## HTTP Status 499

The Connect protocol uses HTTP status 499 for `canceled` errors. Plug doesn't register this status by default. To get a named reason phrase in logs, add to your `config.exs`:

```elixir
config :plug, :statuses, %{499 => "Client Closed Request"}
```

This is optional — the library sends 499 as a raw integer regardless.

## Conformance

Run ConnectRPC server conformance tests:

```bash
./conformance/bin/run
```

This downloads `connectconformance` (cached in `conformance/.cache/`), compiles with `MIX_ENV=test`, and runs in `--mode server`.

## Example

See the greeter example app: [`examples/greeter/`](examples/greeter/)

## License

MIT
