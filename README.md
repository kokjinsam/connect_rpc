# ConnectRPC

ConnectRPC-compatible server for Elixir, implemented as a Phoenix router DSL.

`connect_rpc` v0.2.0 targets [Phoenix.Router](https://hexdocs.pm/phoenix/Phoenix.Router.html) and supports unary RPCs over the Connect protocol.

## Installation

Add `connect_rpc` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:connect_rpc, "~> 0.2.0"}
  ]
end
```

Requires `protobuf` ~> 0.15 for `full_name/0` support on error detail structs.

## Quick Start

### 1. Define protobuf messages

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
```

### 2. Implement a handler

Each RPC method maps to a handler function with the signature `(conn, request)`:

```elixir
defmodule MyApp.GreeterHandler do
  use ConnectRPC.Handler

  def say(_conn, %MyApp.Greet.V1.SayRequest{name: name}) do
    {:ok, %MyApp.Greet.V1.SayResponse{greeting: "Hello, #{name}!"}}
  end
end
```

### 3. Add ConnectRPC routes in your Phoenix router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use ConnectRPC.Router

  service "/connectrpc.greet.v1.GreeterService", MyApp.GreeterHandler do
    rpc "/Say", :say,
      request: MyApp.Greet.V1.SayRequest,
      response: MyApp.Greet.V1.SayResponse
  end
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

Handlers must return one of:

- `{:ok, response_struct}`
- `{:ok, response_struct, metadata}`
- `{:error, %ConnectRPC.Error{}}`
- `{:error, %ConnectRPC.Error{}, metadata}`

Handlers may also `raise ConnectRPC.Error`.

## Error Handling

Return or raise `ConnectRPC.Error` to send Connect error responses:

```elixir
def say(_conn, request) do
  case find_user(request.name) do
    nil ->
      {:error, ConnectRPC.Error.new(:not_found, "user not found")}

    user ->
      {:ok, %SayResponse{greeting: "Hello, #{user.name}!"}}
  end
end
```

Unexpected exceptions are caught and returned as `internal` errors with a sanitized message. Details are logged and emitted via telemetry.

For development, include exception messages in responses by enabling `debug_exceptions`:

```elixir
defmodule MyApp.DebugGreeterHandler do
  use ConnectRPC.Handler, debug_exceptions: true

  def say(_conn, request), do: {:ok, %SayResponse{greeting: request.name}}
end
```

## Router DSL Options

`service/4` accepts options for request decoding and codec negotiation.

### Custom codecs

Built-in codecs:

- `ConnectRPC.Codec.JSON` (`application/json`)
- `ConnectRPC.Codec.Proto` (`application/proto`)

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

Register codecs on a `service` block. This list replaces the defaults:

```elixir
service "/connectrpc.greet.v1.GreeterService", MyApp.GreeterHandler,
  codecs: [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON, MyApp.CustomCodec] do
  rpc "/Say", :say,
    request: SayRequest,
    response: SayResponse
end
```

### Body size/time limits

Configure `Plug.Conn.read_body/2` options per service:

```elixir
service "/connectrpc.greet.v1.GreeterService", MyApp.GreeterHandler,
  read_body_opts: [length: 1_000_000, read_timeout: 15_000] do
  rpc "/Say", :say,
    request: SayRequest,
    response: SayResponse
end
```

## Response Metadata

Handlers may return response headers and trailers via the third tuple element:

```elixir
def say(_conn, request) do
  metadata = %{
    response_headers: [{"x-request-id", "abc123"}],
    response_trailers: [{"x-checksum", "deadbeef"}]
  }

  {:ok, %SayResponse{greeting: "Hello, #{request.name}!"}, metadata}
end
```

Trailers are surfaced as `trailer-<name>` response headers for unary RPCs.

## Pipe Ordering

`service` injects ConnectRPC's internal pipeline plugs (codec negotiation, validation, decoding).

If you add `pipe_through` inside a `service` block, those plugs run after decoding and can access `conn.assigns.connect_rpc_request`.

## Plug.Parsers Compatibility

ConnectRPC reads the request body directly. If an upstream parser consumes the body first, ConnectRPC raises:

`Request body already consumed by an upstream parser. Exclude ConnectRPC paths from Plug.Parsers using the :pass option.`

If your endpoint parses JSON globally, exclude Connect content-types:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["application/proto", "application/json"],
  json_decoder: Jason
```

Note: passing `"application/json"` skips endpoint-level JSON parsing for all routes.

## Telemetry

Events:

- `[:connect_rpc, :handler, :start]` with `%{system_time: integer()}`
- `[:connect_rpc, :handler, :stop]` with `%{duration: integer()}`
- `[:connect_rpc, :handler, :exception]` with `%{duration: integer()}`

Metadata includes `service`, `method`, `codec`, and `path`.

## Migrating from v0.1.x

1. Remove service modules (`__connect_rpc_service__/0` is no longer used).
2. Update handlers from `(request, conn)` to `(conn, request)`.
3. Replace `forward ... ConnectRPC` with `use ConnectRPC.Router` and `service`/`rpc` routes.
4. Move route-specific options (`codecs`, `read_body_opts`) to `service` options.

## Scope

Supported in v0.2.0:

- Connect protocol unary RPCs
- `application/proto` and `application/json`
- Connect-style JSON error responses
- Custom codec registration per service
- Compile-time route validation
- Telemetry events

Out of scope in v0.2.0:

- Streaming (server/client/bidi)
- GET for idempotent RPCs
- Connect-level compression
- gRPC / gRPC-Web protocols

## Limitations

- `Connect-Timeout-Ms` is accepted by the server today but not enforced as a handler deadline.
- GET requests for idempotent RPCs are not supported; unary calls must use POST.
- Request/response compression is not supported (`Content-Encoding` values other than `identity` are rejected), so clients must send uncompressed requests.

## HTTP Status 499

Connect uses HTTP status 499 for `canceled`. Plug does not register this status by default. Optional config:

```elixir
config :plug, :statuses, %{499 => "Client Closed Request"}
```

## Conformance

Run server conformance tests:

```bash
./conformance/bin/run
```

## Example

See the greeter example app: [`examples/greeter/`](examples/greeter/)

## License

MIT
