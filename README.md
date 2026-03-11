# ConnectRPC

ConnectRPC-compatible server for Elixir, implemented as a Phoenix router DSL.

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/kokjinsam/connect_rpc)

## Installation

Add `connect_rpc` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:connect_rpc, "~> 0.4.0"}
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

Each RPC method maps to a handler function with the signature `(request, context)`:

```elixir
defmodule MyApp.GreeterHandler do
  use ConnectRPC.Handler

  def say(%MyApp.Greet.V1.SayRequest{name: name}, _context) do
    {:ok, %MyApp.Greet.V1.SayResponse{greeting: "Hello, #{name}!"}}
  end
end
```

### 3. Configure `Plug.Parsers` in your endpoint

`ConnectRPC.Parser` must run before `:json` so ConnectRPC requests are claimed first while regular JSON requests continue through the normal parser chain.

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, ConnectRPC.Parser, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library()
```

### 4. Add ConnectRPC routes in your Phoenix router

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

### 5. Make a request

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

## Request Context

Handlers receive `%ConnectRPC.Context{}` as the second argument.

- Read values in handlers with `ConnectRPC.Context.get(context, :key)`.
- Populate values from plugs with `ConnectRPC.Context.put(conn, :key, value)`.

## Error Handling

Return or raise `ConnectRPC.Error` to send Connect error responses:

```elixir
def say(request, _context) do
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

  def say(request, _context), do: {:ok, %SayResponse{greeting: request.name}}
end
```

## Parser Configuration

`service/4` no longer accepts ConnectRPC-specific options in v0.4.0. Configure codecs and body-read limits at the endpoint parser level.

Built-in codecs:

- `ConnectRPC.Codec.JSON` (`application/json`)
- `ConnectRPC.Codec.Proto` (`application/proto`)

To override codec negotiation order or allowed codecs:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, {ConnectRPC.Parser, codecs: [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON]}, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library()
```

To configure request body limits/timeouts:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, ConnectRPC.Parser, :json],
  pass: ["*/*"],
  length: 1_000_000,
  read_timeout: 15_000,
  json_decoder: Phoenix.json_library()
```

## Response Metadata

Handlers may return response headers and trailers via the third tuple element:

```elixir
def say(request, _context) do
  metadata = %{
    response_headers: [{"x-request-id", "abc123"}],
    response_trailers: [{"x-checksum", "deadbeef"}]
  }

  {:ok, %SayResponse{greeting: "Hello, #{request.name}!"}, metadata}
end
```

Trailers are surfaced as `trailer-<name>` response headers for unary RPCs.

## Pipe Ordering

`service` injects a single internal plug (`ConnectRPC.Plug.Handler`) for context initialization and request struct casting.

If you add `pipe_through` inside a `service` block, those plugs run after decoding and can access `conn.assigns.connect_rpc_request`.

## Plug.Parsers Compatibility

ConnectRPC now integrates directly with endpoint parsing through `ConnectRPC.Parser`. Add it before `:json` in `Plug.Parsers` so ConnectRPC requests are parsed first while non-Connect JSON requests continue to regular JSON parsing.

## Telemetry

Events:

- `[:connect_rpc, :handler, :start]` with `%{system_time: integer()}`
- `[:connect_rpc, :handler, :stop]` with `%{duration: integer()}`
- `[:connect_rpc, :handler, :exception]` with `%{duration: integer()}`

Metadata includes `service`, `method`, `codec`, and `path`.

## Migrating from v0.2.x

1. Update handler callbacks from `(conn, request)` to `(request, context)`.
2. Move handler inputs derived from `conn` into context via plugs and `ConnectRPC.Context.put/3`.
3. Return tuples from handlers instead of sending responses directly with `Plug.Conn`.

## Migrating from v0.3.x

1. Add `ConnectRPC.Parser` to endpoint `Plug.Parsers` before `:json`.
2. Remove `service/4` ConnectRPC options: `codecs:`, `read_body_opts:`, and `read_body_fun:`.
3. Move codec/body parser configuration to endpoint `Plug.Parsers`.

## Scope

Supported in v0.4.0:

- Connect protocol unary RPCs
- `application/proto` and `application/json`
- Connect-style JSON error responses
- Endpoint-level codec negotiation via `ConnectRPC.Parser`
- Compile-time route validation
- Telemetry events

Out of scope in v0.4.0:

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
