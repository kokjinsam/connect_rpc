# Connect

A native Elixir implementation of the [ConnectRPC](https://connectrpc.com) protocol. Serves ConnectRPC clients (browsers via `@connectrpc/connect-web`, mobile apps, etc.) directly from Phoenix without an Envoy proxy or sidecar.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `connect` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:connect, "~> 0.1.0"}
  ]
end
```

## Supported Features

- **Unary RPCs** -- standard HTTP request/response, no envelope framing
- **Server-streaming RPCs** -- chunked transfer encoding with envelope framing
- **JSON and binary Protobuf** -- automatic codec switching based on `Content-Type`
- **Wire mode validation** -- rejects mismatched content types (e.g., unary content type on a streaming RPC)
- **ConnectRPC error model** -- proper JSON error bodies with code-to-HTTP-status mapping

### Not yet supported

- Client streaming
- Bidirectional streaming
- Compression (`gzip` / `connect-content-encoding`)
- GET requests for idempotent unary RPCs

## Current Scope

This implementation is currently scoped to:

- Unary RPCs
- Server-streaming RPCs

Client-streaming, bidi, and compression are intentionally deferred and tracked below.

## TODO (Future Work)

- [ ] Add client-streaming request support (`stream: :request`) with framed request decoding and unary response handling
- [ ] Add bidi support (`stream: :both`) using a documented buffered-request model
- [ ] Add compression support (`identity`, `gzip`) for unary and streaming:
  - Parse/validate `content-encoding` and `accept-encoding` (unary)
  - Parse/validate `connect-content-encoding` and `connect-accept-encoding` (streaming)
  - Negotiate response encoding and set corresponding response headers
- [ ] Harden streaming request validation:
  - Decode and validate all request envelopes
  - Reject request envelopes with end-stream flag set
  - Reject trailing bytes / malformed framing
- [ ] Add full-body read helper for multi-chunk request bodies with size-limit enforcement
- [ ] Add integration tests for the deferred RPC modes and compression/error negotiation paths

## Quick Start

### 1. Add dependencies

```elixir
# mix.exs
defp deps do
  [
    {:protobuf, "~> 0.12"},
    {:cors_plug, "~> 3.0"}   # if serving browser clients
  ]
end
```

### 2. Define your Protobuf messages

Write `.proto` files and generate Elixir code with `protoc`, or define messages directly:

```elixir
# lib/my_app/eliza/v1/messages.ex
defmodule Eliza.V1.SayRequest do
  use Protobuf, syntax: :proto3
  field :sentence, 1, type: :string
end

defmodule Eliza.V1.SayResponse do
  use Protobuf, syntax: :proto3
  field :sentence, 1, type: :string
end
```

### 3. Define the service

```elixir
# lib/my_app/eliza/v1/eliza_service.ex
defmodule Eliza.V1.ElizaService do
  use Connect.Service

  rpc :Say, Eliza.V1.SayRequest, Eliza.V1.SayResponse
  rpc :Introduce, Eliza.V1.SayRequest, Eliza.V1.SayResponse, stream: :response
end
```

### 4. Implement the handlers

```elixir
# lib/my_app/eliza/server.ex
defmodule MyApp.Eliza.Server do
  # Unary: receives request, returns response struct
  def say(request, _stream) do
    %Eliza.V1.SayResponse{sentence: "You said: #{request.sentence}"}
  end

  # Server-streaming: receives request + stream, sends chunks, returns stream
  def introduce(request, stream) do
    {:ok, stream} = Connect.Stream.send(stream, %Eliza.V1.SayResponse{sentence: "Hi #{request.sentence}"})
    {:ok, stream} = Connect.Stream.send(stream, %Eliza.V1.SayResponse{sentence: "I am Eliza"})
    {:ok, stream} = Connect.Stream.send(stream, %Eliza.V1.SayResponse{sentence: "Nice to meet you"})
    stream
  end
end
```

### 5. Configure the endpoint

Add the body reader to `Plug.Parsers` in your endpoint (see [Body Reader](#body-reader-connectbodyreader) for why):

```elixir
# lib/my_app_web/endpoint.ex
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Phoenix.json_library(),
  body_reader: {Connect.BodyReader, :read_body, []}
```

### 6. Mount in the router

```elixir
# lib/my_app_web/router.ex
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Connect.Router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000"]  # if needed
  end

  scope "/api" do
    pipe_through :api

    connect_service "/eliza.v1.ElizaService",
      service: Eliza.V1.ElizaService,
      impl: MyApp.Eliza.Server
  end
end
```

Your service is now available at `POST /api/eliza.v1.ElizaService/Say` and `POST /api/eliza.v1.ElizaService/Introduce`.

## Handler Contract

Handler functions always take 2 arguments: `(request, stream)`.

| RPC Type         | `request`      | `stream`            | Expected Return                                   |
| ---------------- | -------------- | ------------------- | ------------------------------------------------- |
| Unary            | decoded struct | `nil`               | response struct                                   |
| Server-streaming | decoded struct | `%Connect.Stream{}` | `%Connect.Stream{}` or `{:ok, %Connect.Stream{}}` |

Method names are derived from the proto RPC name converted to snake_case. `SayHello` becomes `say_hello/2`.

### Streaming handlers

Always thread the stream through each send and return the final stream:

```elixir
def introduce(request, stream) do
  {:ok, stream} = Connect.Stream.send(stream, %SayResponse{sentence: "first"})
  {:ok, stream} = Connect.Stream.send(stream, %SayResponse{sentence: "second"})
  stream  # return the stream with its updated conn
end
```

If `Connect.Stream.send/2` returns `{:error, reason}`, the client has disconnected. You can stop sending at that point.

## Content Types

| Content-Type                | Wire Mode | Codec           |
| --------------------------- | --------- | --------------- |
| `application/json`          | Unary     | JSON            |
| `application/proto`         | Unary     | Binary Protobuf |
| `application/connect+json`  | Streaming | JSON            |
| `application/connect+proto` | Streaming | Binary Protobuf |

Parameters like `; charset=utf-8` are stripped before matching. Unsupported content types return HTTP 415.

The wire mode must match the RPC type. Sending `application/json` to a server-streaming RPC (or `application/connect+json` to a unary RPC) returns an `invalid_argument` error.

## Error Handling

### Unary errors

Returned as standard HTTP responses with a JSON body:

```json
{ "code": "not_found", "message": "User not found", "details": [] }
```

The HTTP status code is derived from the Connect error code (`not_found` -> 404, `internal` -> 500, etc.).

### Streaming errors

After `send_chunked(200)` is called, the HTTP status can't change. Errors that occur during streaming are sent in the EndStream frame:

```json
{ "error": { "code": "internal", "message": "Stream failed" } }
```

### Handler crashes

If a handler raises an exception:

- **Unary**: returns HTTP 500 with `{"code": "internal", "message": "Internal server error"}`
- **Streaming**: sends an EndStream frame with the error and logs via `Logger.error`

In both cases, the exception is logged but not exposed to the client.

## Architecture

```
Request
  |
  v
Connect.Plug (init: builds rpc_map from service.__rpc_calls__)
  |
  +--> call/2: route by List.last(conn.path_info)
  |      |
  |      +--> Connect.Protocol: parse content-type, validate wire mode
  |      |
  |      +--> read_raw_body: from conn.private[:raw_body] or read_body
  |      |
  |      +--> Unary path:
  |      |      Connect.Codec.decode -> handler -> Connect.Codec.encode -> send_resp
  |      |
  |      +--> Streaming path:
  |             Connect.Envelope.decode_frame -> Connect.Codec.decode
  |             -> send_chunked(200) -> handler uses Connect.Stream.send
  |             -> finish_stream (Connect.Envelope.wrap_end)
```

### Modules

| Module               | Responsibility                                                    |
| -------------------- | ----------------------------------------------------------------- |
| `Connect.Service`    | `use` macro for defining RPC methods; generates `__rpc_calls__/0` |
| `Connect.Protocol`   | Content-type parsing, wire mode classification, MIME type helpers |
| `Connect.Error`      | Error struct, code-to-HTTP-status mapping, response formatting    |
| `Connect.Codec`      | JSON / binary Protobuf encode and decode dispatch                 |
| `Connect.Envelope`   | 5-byte envelope framing: `[flags:1][length:4][payload:N]`         |
| `Connect.Stream`     | Stateful streaming wrapper around `Plug.Conn.chunk/2`             |
| `Connect.BodyReader` | Caches raw request body for `Plug.Parsers` compatibility          |
| `Connect.Plug`       | Main plug: routing, validation, dispatch, error handling          |
| `Connect.Router`     | Phoenix router macro (`connect_service/2`)                        |

## Body Reader (`Connect.BodyReader`)

This module exists because of a specific interaction with `Plug.Parsers`.

Phoenix's endpoint runs `Plug.Parsers` before the router. When a request arrives with `Content-Type: application/json`, the `:json` parser consumes the body via `Plug.Conn.read_body/2` and decodes it into `conn.body_params` (a plain Elixir map). By the time `Connect.Plug` runs downstream, calling `read_body` again returns an empty binary.

`Connect.BodyReader` intercepts the body read and caches the raw bytes in `conn.private[:raw_body]` as iodata. `Connect.Plug` reads from there instead.

Other content types (`application/proto`, `application/connect+json`, `application/connect+proto`) are unaffected -- `Plug.Parsers` doesn't have parsers for them, so the body is left unconsumed.

**Trade-off**: the raw body is cached for all requests going through `Plug.Parsers`, not just ConnectRPC ones. For typical JSON payloads this is negligible (it's a reference to an already-in-memory binary). If you handle large multipart file uploads and want to avoid the overhead, you can make the caching conditional in `BodyReader.read_body/2` based on content type.

## Service Definition (`Connect.Service`)

The `rpc` macro generates 4-tuples compatible with the shape produced by `grpc-elixir`:

```elixir
{name, {request_module, request_streaming?}, {response_module, response_streaming?}, opts}
```

This means if you later adopt `grpc-elixir` for protoc-generated service definitions, `Connect.Plug` works with those too -- the tuple shape is the same.

### Streaming options

```elixir
rpc :Say, Req, Resp                        # unary
rpc :ServerStream, Req, Resp, stream: :response  # server-streaming
rpc :ClientStream, Req, Resp, stream: :request   # client-streaming (not yet supported)
rpc :BidiStream, Req, Resp, stream: :both        # bidi (not yet supported)
```

## Safety

- **No dynamic atom creation**: impl function atoms are resolved at init time via `impl.__info__(:functions)`, never from untrusted input.
- **Max body size**: 8 MB default (configurable in `Connect.Plug`).
- **Client disconnect**: `finish_stream/2` handles `{:error, :closed}` from `Plug.Conn.chunk/2` gracefully.
- **Handler crashes**: caught via `try/rescue`, logged, and returned as Connect errors. The plug process does not crash.
