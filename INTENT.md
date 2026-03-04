# ConnectRPC for Elixir — Technical Intent

**Package**: `connect_rpc` (Hex)
**Module namespace**: `ConnectRPC`
**Version**: 0.1.0
**License**: MIT
**Minimum**: Elixir 1.14+ / OTP 25+
**Status**: Reference specification for the current v0.1.0 behavior implemented in this repository.

---

## 1. Overview

`connect_rpc` is an Elixir library that implements a **ConnectRPC-compatible server** as a Plug, designed to work inside Phoenix.Router or Plug.Router, running under Bandit or Cowboy.

v0.1.0 supports the Connect protocol (not gRPC or gRPC-Web) for **unary RPCs**, with streaming deferred to a future release.

Users will generate Elixir protobuf modules from `.proto` files using `protobuf-elixir`, then define handler modules that implement RPC methods as plain Elixir functions.

### 1.1 Why Plug Works for Connect (vs gRPC)

A common concern (see [elixir-grpc/grpc#146](https://github.com/elixir-grpc/grpc/issues/146)) is that Plug is designed for HTTP/1.1 request/response semantics while gRPC is built on HTTP/2 streams. This library does **not** suffer from that problem because:

- **Connect uses standard HTTP request/response**, not HTTP/2-specific stream framing. Unary RPCs are plain `POST` requests with simple bodies — exactly what Plug models.
- **Connect works over both HTTP/1.1 and HTTP/2**. The protocol was specifically designed to be web-friendly, unlike gRPC which requires HTTP/2.
- **Plug's abstractions are sufficient**: headers, body reading, and response sending map directly to Connect's needs. There are no gRPC-specific concepts (stream IDs, WINDOW_UPDATE frames, HPACK) that Plug would need to expose.
- **Bandit and Cowboy handle HTTP/2 transparently** — the Plug code is protocol-agnostic, and HTTP/2 features like multiplexing work without library-level awareness.

For future **streaming** support, Plug's `chunk/2` API combined with Connect's envelope framing provides a viable path without breaking the Plug abstraction (see §6.5).

---

## 2. Dependencies

| Dependency                   | Type | Purpose                                 |
| ---------------------------- | ---- | --------------------------------------- |
| `plug`                       | Hard | HTTP abstraction, Plug behavior         |
| `jason`                      | Hard | JSON encoding/decoding                  |
| `protobuf` (protobuf-elixir) | Hard | Protobuf encoding/decoding, message type support |
| `telemetry`                  | Hard | Observability events                    |

No other runtime dependencies. No optional runtime deps in v0.1.0 (dev/test deps are expected).

---

## 3. Module Structure (Public API)

```
ConnectRPC              — Top-level Plug. Mounted per-service in a router.
ConnectRPC.Handler      — `use` macro for defining service handler modules.
ConnectRPC.Error        — Connect error struct (code, message, details).
ConnectRPC.Codec        — Behaviour for codec implementations (extensible).
ConnectRPC.Codec.Proto  — Protobuf binary codec.
ConnectRPC.Codec.JSON   — Proto3 canonical JSON codec.
```

Internal modules (not public API):

```
ConnectRPC.Protocol     — Connect protocol logic (header validation, error formatting).
ConnectRPC.Telemetry    — Telemetry event emission.
```

---

## 4. Service Definition (Macro DSL)

Users define handler modules using a macro and a service module that exports `__connect_rpc_service__/0`:

```elixir
defmodule MyApp.Proto.ConnectRPC.Greet.V1.GreetService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.greet.v1.GreetService",
      methods: [
        %{
          name: "Greet",
          request: MyApp.Proto.ConnectRPC.Greet.V1.GreetRequest,
          response: MyApp.Proto.ConnectRPC.Greet.V1.GreetResponse
        }
      ]
    }
  end
end

defmodule MyApp.GreetHandler do
  use ConnectRPC.Handler,
    service: MyApp.Proto.ConnectRPC.Greet.V1.GreetService

  def greet(%MyApp.Proto.ConnectRPC.Greet.V1.GreetRequest{} = request, conn) do
    {:ok, %MyApp.Proto.ConnectRPC.Greet.V1.GreetResponse{greeting: "Hello, #{request.name}!"}}
  end
end
```

### 4.1 Macro Behavior

The `use ConnectRPC.Handler` macro:

1. Calls `Code.ensure_compiled(service_module)` to verify the service module exists. If not compiled yet, raises a clear compile error:

   > `"Module MyApp.Proto.ConnectRPC.Greet.V1.GreetService must be compiled before MyApp.GreetHandler. Ensure your .proto-generated modules compile before your handler modules."`

2. Calls `service_module.__connect_rpc_service__/0` and normalizes the returned metadata. The metadata must include:
   - Service fully-qualified name (e.g., `connectrpc.greet.v1.GreetService`) via `:name`/`"name"` (or `:service_name` alias)
   - RPC methods via `:methods`/`"methods"` entries with method name, request type, response type, and optional stream flags
   - Method entries may be maps or supported tuples; request/response types may be modules or resolvable type names

   If the service module does not export `__connect_rpc_service__/0`, compilation raises:

   > `"Service module MyApp.Proto.ConnectRPC.Greet.V1.GreetService must export __connect_rpc_service__/0. See the ConnectRPC.Handler documentation for the expected format."`

3. **Compile-time validation**: Checks that the handler module defines a function for each unary RPC method in normalized service metadata. Missing methods raise a compile error:

   > `"MyApp.GreetHandler is missing handler function greet/2 for RPC method Greet defined in connectrpc.greet.v1.GreetService"`

4. Stores the service metadata in module attributes for use by the Plug at runtime.

### 4.2 Handler Function Signature

Each RPC method maps to a function named after the **snake_case** version of the method name:

```
Proto method "SayHello" → Elixir function say_hello/2
Proto method "Greet"    → Elixir function greet/2
```

**Signature**: `method_name(request_struct, conn) :: {:ok, response_struct} | {:error, %ConnectRPC.Error{}}`

- `request_struct` — The decoded protobuf struct (e.g., `%MyApp.Proto.ConnectRPC.Greet.V1.GreetRequest{}`)
- `conn` — The raw `Plug.Conn` struct, giving handlers full HTTP access (request headers, peer info, etc.)
- Returns `{:ok, response_struct}` on success
- Returns `{:error, %ConnectRPC.Error{}}` on handled errors
- May also `raise %ConnectRPC.Error{}` for error flow control

**Experimental** (v0.1.0): Handlers may also return a 3-tuple with response metadata:

```elixir
{:ok, response_struct, %{headers: [{"x-custom", "value"}]}}
{:error, %ConnectRPC.Error{}, %{headers: [{"x-custom", "value"}]}}
{:ok, response_struct, %{response_headers: [{"x-custom", "value"}], response_trailers: [{"x-meta", "value"}]}}
{:error, %ConnectRPC.Error{}, %{response_headers: [{"x-custom", "value"}], response_trailers: [{"x-meta", "value"}]}}
```

Supported aliases are `headers`/`response_headers` and `trailers`/`response_trailers` (map or keyword-list metadata). For unary RPCs, trailers are emitted as `trailer-<name>` response headers.

Supported metadata entry shapes:

- `{"x-name", "value"}` or `{"x-name", ["v1", "v2"]}`
- `%{name: "x-name", value: "value"}` or `%{name: "x-name", value: ["v1", "v2"]}`
- `%{"name" => "x-name", "value" => "value"}` or `%{"name" => "x-name", "value" => ["v1", "v2"]}`

Header/trailer names are normalized to lowercase and must use RFC 7230 token characters; values must not contain CR/LF characters. Duplicate metadata entries are preserved in the order returned by the handler.

Invalid metadata raises an argument error in the server and is surfaced to clients as a Connect `internal` error response (sanitized unless `debug_exceptions: true`).

This allows setting custom response headers/trailers without reaching into `conn` directly. The metadata shape may change in future versions.

> **Design decision**: Handlers receive the raw `Plug.Conn` for v0.1.0. A restricted `ConnectRPC.Context` struct may be introduced in a future version to prevent footguns (e.g., calling `send_resp/3` directly). The raw conn approach is familiar to Phoenix developers and provides full HTTP access when needed.

### 4.3 Streaming Preparation

In v0.1.0, only unary RPCs are supported. The macro skips non-unary methods (server streaming, client streaming, bidi) and emits a compile-time warning:

> `"Skipping streaming method ServerGreet - streaming is not yet supported in connect_rpc v0.1.0"`

Skipped streaming methods are not added to the runtime unary dispatch table. Requests to those RPC paths therefore resolve through the unknown-method path and return Connect `unimplemented` (HTTP 501).

When streaming is added in a future version, additional function signatures will be defined (e.g., returning a stream struct), but the existing unary `method_name/2` pattern will remain unchanged.

---

## 5. Routing (Plug Integration)

### 5.1 Single Mount-Point Per Service

Each service is mounted as a single Plug in the router. The Plug internally dispatches to the correct handler function based on the request path.

**Phoenix.Router example:**

```elixir
defmodule MyApp.Router do
  use Phoenix.Router

  forward "/connectrpc.greet.v1.GreetService",
    ConnectRPC,
    handler: MyApp.GreetHandler
end
```

**Plug.Router example:**

```elixir
defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/connectrpc.greet.v1.GreetService",
    to: ConnectRPC,
    init_opts: [handler: MyApp.GreetHandler]
end
```

### 5.2 Path Format

Connect routes follow the format: `POST /<package>.<Service>/<Method>`

The Plug receives requests at `/<Method>` (after the router strips the service prefix via `forward`). It matches the method name against the handler's known RPC methods.

### 5.3 Unknown Methods

A request to a valid service but unknown method returns Connect error code **`unimplemented`** with HTTP status **501** and a message like:

> `"Method DoesNotExist is not implemented by connectrpc.greet.v1.GreetService"`

---

## 6. Connect Protocol Implementation

### 6.1 Unary Request Flow

1. **Method validation**: Verify the HTTP method is POST. If not, return HTTP 405.
2. **Content-type negotiation**: Parse the `Content-Type` media type (ignoring optional parameters such as `charset=utf-8`):
   - `application/proto` → Protobuf binary codec
   - `application/json` → Proto3 JSON codec
   - Anything else → HTTP **415** with a JSON-encoded Connect error body (`code: "unknown"`, `message: "Unsupported content type: <type>"`)
3. **Protocol header validation** (strict): Verify `Connect-Protocol-Version: 1` header is present. If missing, return Connect error `invalid_argument`:
   > `"Missing required Connect-Protocol-Version header"`
4. **Compression check**: Normalize `Content-Encoding` header values (`trim + lowercase`). The request is accepted only when the resulting list is empty or exactly `["identity"]`. Any other value/pattern returns Connect error `unimplemented`:
   > `"Compression is not supported"`
5. **Body parser detection**: Check if the request body was already consumed by an upstream parser (e.g., `Plug.Parsers`). If `conn.body_params` is not `%Plug.Conn.Unfetched{}`, raise a clear runtime error:
   > `"Request body already consumed by an upstream parser. Exclude ConnectRPC paths from Plug.Parsers using the :pass option."`
6. **Body reading**: Read the request body via `Plug.Conn.read_body/2` in a loop until completion (`{:more, chunk, conn}` then `{:ok, chunk, conn}`), using the library's default `read_body` limits/options.
   - Request size/time behavior is dictated by the configured/default `Plug.Conn.read_body/2` options used by `ConnectRPC`.
   - On Connect routes, request body ownership must remain with `ConnectRPC` (upstream body parsers should not consume Connect RPC bodies before this step).
   - If body reading returns `{:error, :too_large}`, return HTTP **413** with Connect error `resource_exhausted` and message `"Request body too large"`.
   - If body reading returns `{:error, :timeout}`, return HTTP **504** with Connect error `deadline_exceeded` and message `"Request body read timed out"`.
   - For any other body-read error (`{:error, reason}`), return HTTP **500** with Connect error `internal` and message `"Failed to read request body"`.
7. **Decoding**: Decode the body using the negotiated codec into the expected request struct.
   - If decoding fails (invalid JSON or protobuf payload), return HTTP **400** with Connect error `invalid_argument` and message `"Invalid request body"`. Decode error messages are always sanitized — no byte offsets or field details are exposed to the client.
8. **Handler invocation**: Call `handler_module.method_name(request_struct, conn)`.
9. **Double-send detection**: After the handler returns, verify that `conn.state` is not `:sent`. If the handler called `Plug.Conn.send_resp/3` directly, raise a clear error:
   > `"Handler sent a response directly via Plug.Conn. Use {:ok, response} or {:error, %ConnectRPC.Error{}} return values instead."`
10. **Response encoding**: Encode the response struct using the same codec as the request.
11. **Type check at encode time**: If the handler returns a value that is not the expected response struct type, raise a clear error and return Connect `internal` error to the client:
    > `"Expected MyApp.Proto.ConnectRPC.Greet.V1.GreetResponse, got %{foo: \"bar\"}"`
12. **Response**: Send HTTP 200 with:
    - `Content-Type: application/proto` or `application/json` (matching request)
    - Encoded response body

### 6.2 Unary Error Response Format

Connect errors are returned as JSON regardless of the request content-type:

```
HTTP/1.1 <mapped_status>
Content-Type: application/json

{
  "code": "<connect_error_code>",
  "message": "<error message>"
}
```

With optional `details` array (when `ConnectRPC.Error` has details):

```json
{
  "code": "invalid_argument",
  "message": "name is required",
  "details": [
    {
      "type": "google.rpc.BadRequest",
      "value": "<base64-encoded protobuf bytes>"
    }
  ]
}
```

### 6.3 Connect Error Code → HTTP Status Mapping

| Connect Code          | HTTP Status |
| --------------------- | ----------- |
| `canceled`            | 499         |
| `unknown`             | 500         |
| `invalid_argument`    | 400         |
| `deadline_exceeded`   | 504         |
| `not_found`           | 404         |
| `already_exists`      | 409         |
| `permission_denied`   | 403         |
| `resource_exhausted`  | 429         |
| `failed_precondition` | 400         |
| `aborted`             | 409         |
| `out_of_range`        | 400         |
| `unimplemented`       | 501         |
| `internal`            | 500         |
| `unavailable`         | 503         |
| `data_loss`           | 500         |
| `unauthenticated`     | 401         |

### 6.4 Compression

v0.1.0 supports **no Connect-level compression handling**. The request passes only when normalized `Content-Encoding` values are empty or exactly `["identity"]`; all other values/patterns return:

- Connect error code: `unimplemented`
- Message: `"Compression is not supported"`

No Connect-level `Accept-Encoding` negotiation or compressed envelope handling is implemented.

HTTP-layer response compression (if any) is outside `connect_rpc` protocol logic and controlled by user-selected server/middleware configuration.

### 6.5 Streaming Architecture (Deferred — Design Decisions)

Although streaming is deferred to a future version, key architectural decisions have been made to guide the implementation:

#### 6.5.1 Envelope Framing

The Connect streaming wire format uses envelope frames:

```
frame = <flags:uint8> <length:uint32be> <message:bytes>
```

- `flags`: Bit 0 = compressed, Bit 1 = end-of-stream (trailers frame), Bits 2-7 = reserved
- `length`: 4-byte big-endian unsigned integer, byte length of `message`
- `message`: Protobuf or JSON encoded message bytes

This is NOT used for unary RPCs (which use simple request/response bodies).

#### 6.5.2 End-of-Stream: Envelope-Only (No HTTP Trailers)

The library will use **end-of-stream envelope frames** to carry the final RPC status, rather than HTTP trailers. The final status (error code, message, trailing metadata) is encoded as a special envelope frame with the end-of-stream flag bit set.

**Rationale**: Plug has no first-class trailer API. Using real HTTP trailers would require adapter-specific code paths (Cowboy's `:cowboy_req.stream_trailers/2` vs Bandit's trailer API), breaking the Plug abstraction. The envelope-only approach:

- Works identically on any Plug-compatible adapter
- Is already how `connect-web` (browser client) works, since browsers cannot read HTTP trailers
- Is supported by all Connect client implementations (connect-go, connect-web, connect-es)

#### 6.5.3 Backpressure: Fire-and-Forget via Plug.Conn.chunk/2

Server streaming will use `Plug.Conn.chunk/2` to send data frames. This provides no explicit backpressure signal — the library writes chunks and relies on TCP-level flow control (the adapter's `send()` blocks when TCP send buffers are full).

**Rationale**: This is the same approach used by Phoenix LiveView and Server-Sent Events. Most RPC messages are small enough that buffer overflow is unlikely. Implementing adapter-aware flow control (hooking into Bandit/Cowboy internals) would break the Plug abstraction for marginal benefit. TCP backpressure is sufficient for the expected use cases.

---

## 7. Error Handling

### 7.1 ConnectRPC.Error Struct

```elixir
defmodule ConnectRPC.Error do
  @type code ::
    :canceled | :unknown | :invalid_argument | :deadline_exceeded |
    :not_found | :already_exists | :permission_denied | :resource_exhausted |
    :failed_precondition | :aborted | :out_of_range | :unimplemented |
    :internal | :unavailable | :data_loss | :unauthenticated

  @type t :: %__MODULE__{
    code: code(),
    message: String.t(),
    details: [term()]
  }

  defexception code: :unknown, message: "", details: []
end
```

- `code` — One of the 16 standard Connect error codes (as atoms)
- `message` — Human-readable error message
- `details` — List of detail entries. Supported entries are:
  - protobuf message structs (e.g., `Google.Rpc.BadRequest`)
  - pre-encoded maps `%{type: "<protobuf full name>", value: <<raw protobuf bytes>>}` (or string-key equivalent)
  Serialized wire shape is `{"type": "<fully-qualified message name>", "value": "<base64>"}`. Default: `[]`

**Detail type resolution**: For struct entries, each detail module **must** export `full_name/0` (provided by `protobuf-elixir` >= 0.15.0) to determine the fully-qualified protobuf type name. If a detail struct's module does not export `full_name/0`, the library raises at encode time:

> `"Detail struct MyModule does not expose full_name/0. Error details must be protobuf-generated message structs (protobuf-elixir >= 0.15.0)."`

This ensures correct type URLs in the wire format. The Elixir module name (e.g., `Google.Rpc.BadRequest`) is not the same as the protobuf type name (e.g., `google.rpc.BadRequest`) and cannot be reliably converted.

**Detail encoding failure**: If error detail encoding fails (e.g., invalid detail struct, missing `full_name/0`, encoding error), the library logs the failure at `:error` level and falls back to returning a generic `internal` error response (`{"code": "internal", "message": "internal error"}` with HTTP 500). The original error is not sent to the client.

### 7.2 Handler Error Patterns

Handlers can signal errors in two ways:

```elixir
# Return an error tuple
def greet(request, conn) do
  {:error, %ConnectRPC.Error{code: :invalid_argument, message: "name is required"}}
end

# Raise an error
def greet(request, conn) do
  raise ConnectRPC.Error, code: :not_found, message: "user not found"
end
```

### 7.3 Unexpected Exception Handling

When a handler raises an exception that is NOT a `ConnectRPC.Error`, the library:

1. Catches the exception
2. Returns Connect error code `internal` with a sanitized message by default:
   ```json
   { "code": "internal", "message": "internal error" }
   ```
3. Logs the full stacktrace at `:error` level via `Logger`
4. Emits `[:connect_rpc, :handler, :exception]` telemetry with exception metadata

If `debug_exceptions: true` is configured (intended for development/test), the response message includes the raw exception message:

```json
{ "code": "internal", "message": "** (RuntimeError) something went wrong" }
```

> **Design decision**: unexpected exceptions are sanitized by default for production safety. Debugging details remain available in logs and telemetry, with optional response-level verbosity in development.

---

## 8. Codecs

### 8.0 Codec Behaviour (`ConnectRPC.Codec`)

Codecs implement the `ConnectRPC.Codec` behaviour:

```elixir
@callback media_type() :: String.t()
@callback encode(struct()) :: {:ok, iodata()} | {:error, term()}
@callback decode(binary(), module()) :: {:ok, struct()} | {:error, term()}
```

The library ships with two built-in codecs: `ConnectRPC.Codec.Proto` and `ConnectRPC.Codec.JSON`.

**Registration**: Codecs are registered at init time via the `codecs` option. By default, the library includes both built-in codecs. If a user provides a `codecs` list, it **fully replaces** the defaults — the user must explicitly include the built-in codecs if they want them:

```elixir
# Default: proto + json
forward "/service", ConnectRPC, handler: MyHandler

# Custom: proto + json + messagepack
forward "/service", ConnectRPC,
  handler: MyHandler,
  codecs: [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON, MyApp.Codec.MessagePack]

# Custom: json only (no proto support)
forward "/service", ConnectRPC,
  handler: MyHandler,
  codecs: [ConnectRPC.Codec.JSON]
```

Content-type negotiation matches the request's `Content-Type` against each codec's `media_type/0` in list order. First match wins.

### 8.1 Protobuf Binary Codec (`ConnectRPC.Codec.Proto`)

- Content-Type: `application/proto`
- Encoding: Delegates to `protobuf-elixir`'s `Module.encode/1` and `Module.decode/2`
- Straightforward pass-through to the generated protobuf modules

### 8.2 Proto3 JSON Codec (`ConnectRPC.Codec.JSON`)

- Content-Type: `application/json`
- Delegates encoding/decoding to `protobuf-elixir` (`Protobuf.JSON`)
- `connect_rpc` does not add a JSON transformation layer in v0.1.0; runtime behavior follows `protobuf-elixir` semantics for the loaded protobuf modules

#### 8.2.1 Field Name Mapping

- For protoc-generated modules, JSON keys follow each field's `json_name` metadata (typically **lowerCamelCase**)
- The decoder accepts both proto field-name and `json_name` variants when `protobuf-elixir` supports both
- Modules defined without explicit `json_name` metadata may emit/accept only the declared field name

#### 8.2.2 Default Value Omission

- Proto3 default values are omitted in JSON output for generated modules when `protobuf-elixir` emits canonical omissions

#### 8.2.3 Oneof Fields

- `protobuf-elixir` represents oneofs as `{:field_name, value}` tuples
- Oneof JSON serialization/deserialization is handled by `protobuf-elixir`
- Only the set field of a oneof appears in JSON output

#### 8.2.4 Enum Fields

- Serialized as **string names** in JSON (e.g., `"FOO_BAR"`)
- Deserialized from both string names and integer values

#### 8.2.5 Well-Known Type Support (v0.1.0 — Core Types)

| Type                          | JSON Representation                         |
| ----------------------------- | ------------------------------------------- |
| `google.protobuf.Timestamp`   | RFC 3339 string (`"2024-01-15T10:30:00Z"`)  |
| `google.protobuf.Duration`    | Seconds string (`"1.5s"`)                   |
| `google.protobuf.DoubleValue` | Number or null                              |
| `google.protobuf.FloatValue`  | Number or null                              |
| `google.protobuf.Int64Value`  | Number or null (current `protobuf-elixir` behavior) |
| `google.protobuf.UInt64Value` | Number or null (current `protobuf-elixir` behavior) |
| `google.protobuf.Int32Value`  | Number or null                              |
| `google.protobuf.UInt32Value` | Number or null                              |
| `google.protobuf.BoolValue`   | Boolean or null                             |
| `google.protobuf.StringValue` | String or null                              |
| `google.protobuf.BytesValue`  | Base64 string or null                       |
| `google.protobuf.Empty`       | Empty JSON object (`{}`)                    |

**Additional well-known types** (`Struct` / `Value` / `ListValue` / `Any` / `FieldMask`) are delegated to `protobuf-elixir` behavior in v0.1.0.

#### 8.2.6 Bytes Fields

- Serialized as **standard base64** (RFC 4648) in JSON output
- Deserialized from both standard and URL-safe base64

#### 8.2.7 64-bit Integer Fields

- `int64`, `uint64`, `sint64`, `fixed64`, `sfixed64` are serialized as **JSON strings** to avoid JavaScript precision loss
- Deserialized from both strings and numbers

---

## 9. Telemetry

The library emits telemetry events following Phoenix's naming convention.

By default, telemetry metadata should stay lightweight and avoid including full `Plug.Conn` structs to reduce payload size and accidental leakage of request data.

### 9.1 Events

#### `[:connect_rpc, :handler, :start]`

Emitted when a handler function is about to be invoked.

**Measurements**: `%{system_time: integer()}`

**Metadata**:

```elixir
%{
  service: String.t(),     # "connectrpc.greet.v1.GreetService"
  method: String.t(),      # "Greet"
  codec: String.t(),       # "application/proto" or "application/json" (media type)
  path: String.t()
}
```

#### `[:connect_rpc, :handler, :stop]`

Emitted after a handler function returns successfully.

**Measurements**: `%{duration: integer()}` (native time units)

**Metadata**:

```elixir
%{
  service: String.t(),
  method: String.t(),
  codec: String.t(),
  path: String.t()
}
```

#### `[:connect_rpc, :handler, :exception]`

Emitted when a handler function raises an exception (including `ConnectRPC.Error`).

**Measurements**: `%{duration: integer()}`

**Metadata**:

```elixir
%{
  service: String.t(),
  method: String.t(),
  codec: String.t(),
  path: String.t(),
  kind: :error | :exit | :throw,
  reason: term(),
  stacktrace: list()
}
```

### 9.2 Logging

The library logs each request at **`:debug`** level with service name, method name, codec, duration, and result. This is invisible in production (default log level is `:info`) but useful during development.

Example log line:

```
[debug] ConnectRPC connectrpc.greet.v1.GreetService/Greet codec=application/json duration=1.2ms status=ok
```

Errors (handler crashes, codec failures) are logged at `:error` level with full stacktraces.

---

## 10. Content-Type Negotiation

### 10.1 Request Content-Type

With default codecs:

| Content-Type        | Codec Used                         |
| ------------------- | ---------------------------------- |
| `application/proto` | `ConnectRPC.Codec.Proto`           |
| `application/json`  | `ConnectRPC.Codec.JSON`            |
| Anything else       | HTTP 415 + Connect error JSON body |

When custom codecs are registered (see §8.0), the `Content-Type` is matched against each codec's `media_type/0` in list order.

Media-type parameters are ignored during negotiation. For example, `application/json; charset=utf-8` is treated as `application/json`.

### 10.2 Response Content-Type

The response content-type mirrors the negotiated codec (not request parameters). JSON responses use `application/json`; protobuf responses use `application/proto`.

### 10.3 Error Responses

Error responses are **always JSON** (`Content-Type: application/json`), regardless of the request content-type. This matches the Connect protocol spec.

---

## 11. Protocol Validation (Strict Mode)

The library enforces strict Connect protocol compliance:

1. **HTTP method**: Only `POST` is accepted for unary RPCs. Other methods return HTTP 405 Method Not Allowed.
2. **Content-Type header**: Media type must be `application/proto` or `application/json` (parameters are allowed). Others return HTTP 415 + Connect error code `unknown`.
3. **Connect-Protocol-Version header**: Must be present with value `1`. Missing or wrong value returns Connect error `invalid_argument`.
4. **Content-Encoding**: The normalized header list must be empty or exactly `["identity"]`; otherwise returns Connect error `unimplemented`.

### 11.1 gRPC / gRPC-Web

No special handling for `application/grpc` or `application/grpc-web` content types. They will fail content-type negotiation like any other unsupported type (HTTP 415).

### 11.2 Body Parser Ownership

For Connect routes, endpoint/body parser configuration must not consume Connect request bodies before `ConnectRPC` handles them. This keeps decoding and Connect error formatting in one place and prevents non-Connect parser errors from being returned on Connect endpoints.

`ConnectRPC` is responsible for reading Connect request bodies and mapping body-read failures (for example, `:too_large`, `:timeout`) into Connect-formatted error responses.

If a hard upstream limit (adapter/server/other middleware) rejects the request before it reaches `ConnectRPC`, the response may not be Connect-formatted.

**Runtime detection**: The library checks at the start of request processing whether the body was already consumed by an upstream parser (e.g., `Plug.Parsers`). If `conn.body_params` is not `%Plug.Conn.Unfetched{}`, the library raises a clear error directing the user to exclude Connect paths from their body parser configuration. This prevents hours of debugging empty-body decode errors.

Users should configure `Plug.Parsers` with the `:pass` option to skip Connect content types, or ensure Connect routes bypass `Plug.Parsers` entirely.

---

## 12. Deferred Features (Not in v0.1.0)

The following features are explicitly deferred and will not be in the initial release:

| Feature                                          | Notes                                                                 |
| ------------------------------------------------ | --------------------------------------------------------------------- |
| **Server streaming**                             | Requires chunked transfer encoding, envelope framing                  |
| **Client streaming**                             | Requires request body chunk reading                                   |
| **Bidirectional streaming**                      | Requires both of the above                                            |
| **GET requests for idempotent RPCs**             | Query param encoding, base64url message                               |
| **Interceptors**                                 | Typed middleware wrapping RPC calls                                   |
| **Connect-Timeout-Ms / handler timeout**         | Deadline propagation and handler invocation timeout deferred together |
| **Connect-level compression (gzip)**             | Compression negotiation + compressed envelope framing                 |
| **Stable response metadata API**                 | Experimental 3-tuple return (`headers`/`trailers` aliases supported in v0.1.0); stable API deferred |
| **Test helpers**                                 | `ConnectRPC.Test` module for handler unit testing                     |
| **Health check**                                 | No built-in health endpoint                                           |
| **CORS Plug**                                    | Documented but not implemented                                        |
| **Well-known types: Struct/Value/Any/FieldMask** | Only core types supported                                             |
| **Public runtime introspection API**             | Internal `__connect_rpc__/1` exists for framework plumbing; no stable public introspection API yet |

In v0.1.0, requests targeting deferred streaming method paths are treated as unknown methods and return Connect `unimplemented` (HTTP 501).

---

## 13. CORS (Documentation Only)

The library does not ship CORS middleware and does not enforce a CORS policy.

Users should configure CORS entirely in userland with whichever middleware/library they prefer.

---

## 14. Request Body Size Limits

Request body size/time behavior is defined by the `Plug.Conn.read_body/2` options used by `ConnectRPC` (defaults unless customized).

Request body handling for Connect routes should follow these rules:

- Read via `Plug.Conn.read_body/2` in a loop until complete (`:more` handling required).
- Keep default limits or override intentionally via the library's body-read options.
- Ensure endpoint body parsers do not pre-consume Connect RPC request bodies.
- Map `{:error, :too_large}` to HTTP 413 + Connect `resource_exhausted`.
- Map `{:error, :timeout}` to HTTP 504 + Connect `deadline_exceeded`.
- Map other body-read errors to HTTP 500 + Connect `internal`.
- Decode failures (invalid JSON/protobuf payload) return HTTP 400 + Connect `invalid_argument`.
- Do not invoke handler functions when body read or decode fails.

---

## 15. Example Application

The repository includes a working example Phoenix application at `examples/greeter/`:

```
examples/greeter/
├── mix.exs
├── proto/
│   └── greet.proto
├── lib/
│   └── greeter_example/
│       ├── application.ex
│       ├── endpoint.ex
│       ├── error_json.ex
│       ├── gen/
│       │   └── greet.pb.ex  # Generated protobuf modules
│       ├── proto.ex          # Service metadata (`__connect_rpc_service__/0`)
│       ├── handler.ex
│       └── router.ex
└── test/
    └── greeter_example/
        └── router_test.exs
```

The example demonstrates:

- A `.proto` file with a simple Greet service
- Generated protobuf modules (committed to the repo)
- A handler module implementing the RPC methods
- Router configuration with `forward`
- Integration tests making HTTP requests

---

## 16. Testing Strategy

### 16.1 Internal Tests (ExUnit)

Comprehensive ExUnit tests covering:

- Codec encoding/decoding (proto and JSON)
- JSON field name mapping (camelCase)
- JSON oneof handling
- JSON well-known type serialization
- JSON default value omission
- Error struct creation and serialization
- Protocol header validation
- Content-type negotiation
- Unknown method handling
- Handler invocation and response encoding
- Body-read error mapping (`:too_large`, `:timeout`, other read errors)
- Decode failure mapping (invalid JSON/protobuf payload -> `invalid_argument`)
- Handler is not invoked when body read/decode fails
- Type mismatch error handling
- Unexpected exception handling
- Compression rejection
- Telemetry event emission

### 16.2 Conformance Tests (CI)

The official [ConnectRPC conformance test suite](https://github.com/connectrpc/conformance) is integrated into CI from day one.

- The conformance runner (Go binary) is fetched as a CI dependency
- A test server is started using the library
- The conformance suite sends requests and validates responses
- CI fails if any conformance test fails
- CI quality gates include format check, warnings-as-errors compile, tests, known-failing policy check, and conformance execution
- v0.1.0 conformance execution scope is unary RPC behavior over HTTP/1.1 (streaming coverage is deferred with streaming support)

This provides strong protocol correctness guarantees and catches edge cases that hand-written tests might miss.

---

## 17. Project Structure

Current v0.1.0 layout:

```
connect_rpc/
├── mix.exs
├── LICENSE                   # MIT
├── README.md
├── CHANGELOG.md
├── .formatter.exs
├── .github/
│   └── workflows/
│       └── ci.yml            # ExUnit + conformance tests
├── lib/
│   ├── connect_rpc.ex        # Main Plug module
│   ├── connect_rpc/
│   │   ├── handler.ex        # `use` macro and handler behavior
│   │   ├── error.ex          # Error struct (defexception)
│   │   ├── protocol.ex       # Protocol logic (validation, error formatting)
│   │   ├── telemetry.ex      # Telemetry event helpers
│   │   └── codec/
│   │       ├── proto.ex      # Protobuf binary codec
│   │       └── json.ex       # Proto3 JSON codec
├── test/
│   ├── test_helper.exs
│   ├── connect_rpc_test.exs
│   ├── connect_rpc/
│   │   ├── handler_test.exs
│   │   ├── error_test.exs
│   │   ├── protocol_test.exs
│   │   └── codec/
│   │       ├── proto_test.exs
│   │       └── json_test.exs
│   └── support/
│       ├── proto/            # Test .proto definitions
│       ├── gen/              # Generated protobuf modules for tests
│       ├── conformance/      # Conformance runtime + generated modules
│       └── test_modules_helper.exs
└── examples/
    └── greeter/              # Example Phoenix app
```

---

## 18. mix.exs

```elixir
defmodule ConnectRPC.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/kokjinsam/connect_rpc"

  def project do
    [
      app: :connect_rpc,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "ConnectRPC",
      description: "ConnectRPC-compatible server for Phoenix/Plug",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test) do
    [
      "lib",
      "test/support/gen",
      "test/support/conformance/runtime",
      "test/support/conformance/gen"
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:protobuf, "~> 0.15"},
      {:telemetry, "~> 1.0"},

      # Dev/test
      {:bandit, "~> 1.7", only: :test},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:styler, "~> 1.11", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "ConnectRPC",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
```

---

## 19. Usage Summary

### Step 1: Define your .proto

```protobuf
syntax = "proto3";
package connectrpc.greet.v1;

service GreetService {
  rpc Greet (GreetRequest) returns (GreetResponse) {}
}

message GreetRequest {
  string name = 1;
}

message GreetResponse {
  string greeting = 1;
}
```

### Step 2: Generate Elixir modules

```bash
protoc --elixir_out=./lib/my_app/proto greet.proto
```

### Step 3: Implement handler

```elixir
defmodule MyApp.GreetHandler do
  use ConnectRPC.Handler,
    service: MyApp.Proto.ConnectRPC.Greet.V1.GreetService

  def greet(%MyApp.Proto.ConnectRPC.Greet.V1.GreetRequest{} = request, _conn) do
    {:ok, %MyApp.Proto.ConnectRPC.Greet.V1.GreetResponse{
      greeting: "Hello, #{request.name}!"
    }}
  end
end
```

### Step 4: Mount in router

```elixir
defmodule MyApp.Router do
  use Phoenix.Router

  forward "/connectrpc.greet.v1.GreetService",
    ConnectRPC,
    handler: MyApp.GreetHandler
end
```

### Step 5: Client request

```bash
curl -X POST http://localhost:4000/connectrpc.greet.v1.GreetService/Greet \
  -H "Content-Type: application/json" \
  -H "Connect-Protocol-Version: 1" \
  -d '{"name": "World"}'

# Response: {"greeting": "Hello, World!"}
```

---

## 20. Decision Log

| #   | Decision                   | Choice                                                 | Rationale                                                                      |
| --- | -------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------ |
| 1   | Service definition         | Macro-based DSL + `__connect_rpc_service__/0` metadata | Keeps handler wiring explicit while preserving low boilerplate                 |
| 2   | Protobuf library           | protobuf-elixir                                        | Most maintained; provides encode/decode + `full_name/0` support               |
| 3   | GET for idempotent RPCs    | Deferred                                               | Simplifies v0.1.0, addable without breaking changes                            |
| 4   | Interceptors               | Deferred                                               | Users can use Plug middleware; typed interceptors with streaming               |
| 5   | JSON codec                 | Delegated to `protobuf-elixir` (`Protobuf.JSON`)      | Keeps implementation lean and aligned with protobuf ecosystem behavior          |
| 6   | Error API                  | Custom exception struct                                | `%ConnectRPC.Error{code, message, details}` — raiseable and returnable         |
| 7   | Unexpected exceptions      | Sanitize by default + opt-in debug message             | Secure-by-default; raw exception messages available in dev/test                |
| 8   | Timeout handling           | Deferred                                               | Most users won't need server-side deadline enforcement initially               |
| 9   | Routing                    | Single mount per service                               | Clean, minimal router config via `forward`                                     |
| 10  | Protocol header validation | Strict                                                 | Spec-compliant; rejects non-Connect traffic                                    |
| 11  | Package name               | `connect_rpc` / `ConnectRPC`                           | Clear, maps to protocol name                                                   |
| 12  | gRPC content types         | No special handling                                    | Fail naturally via content-type negotiation                                    |
| 13  | Handler signature          | `method(request, conn) → {:ok, resp} \| {:error, err}` | Full HTTP access, familiar to Phoenix devs                                     |
| 14  | Response metadata          | Experimental in v0.1.0                                | Supports practical conformance/user needs while keeping API flexible            |
| 15  | Conformance tests          | CI from day one                                        | Gold standard for protocol correctness                                         |
| 16  | Test helpers               | Deferred                                               | Ship based on user feedback                                                    |
| 17  | JSON well-known types      | Core types explicitly covered; others delegated        | Keeps guarantees where tested while allowing protobuf-elixir passthrough        |
| 18  | JSON default omission      | Omit defaults                                          | Spec-recommended, smaller payloads                                             |
| 19  | Content-type errors        | HTTP 415 + Connect error JSON body (`code: "unknown"`) | Matches conformance expectations and current implementation                     |
| 20  | Concurrency controls       | None                                                   | Delegate to Bandit/Cowboy; each request is a process                           |
| 21  | CORS                       | Userland only                                          | Users choose and configure their own CORS stack/policy                         |
| 22  | Compile-time validation    | Yes                                                    | Catches missing handlers early; clear error messages                           |
| 23  | Elixir/OTP version         | 1.14+ / OTP 25+                                        | ~2 year support window, broad compatibility                                    |
| 24  | Body size limits           | `Plug.Conn.read_body/2` defaults                       | Predictable defaults with explicit opt-in override behavior                    |
| 25  | Compression                | No Connect-level handling                              | Accept only empty/`["identity"]` normalized `Content-Encoding`; otherwise `unimplemented` |
| 26  | Dependencies               | plug + jason + protobuf + telemetry                    | Minimal but includes observability from day one                                |
| 27  | Telemetry naming           | `[:connect_rpc, :handler, :start/stop/exception]`      | Matches Phoenix convention                                                     |
| 28  | Introspection function     | Internal `__connect_rpc__/1` only                      | Required for runtime plumbing; no additional stable introspection API          |
| 29  | Unknown method error       | `unimplemented`                                        | Matches connect-go and gRPC semantics                                          |
| 30  | Handler callbacks          | Method-name functions (snake_case)                     | Most Elixir-idiomatic, one function per RPC                                    |
| 31  | Compile order              | `Code.ensure_compiled` + clear error                   | Catches issues at compile time with helpful messages                           |
| 32  | Health check               | None                                                   | Application-level concern                                                      |
| 33  | Module structure           | Flat namespace                                         | Simple, discoverable public API                                                |
| 34  | Initial version            | 0.1.0                                                  | Signals early development, no stability promises                               |
| 35  | Example app                | In-repo at `examples/greeter/`                         | Clone-and-run documentation                                                    |
| 36  | License                    | MIT                                                    | Most common in Elixir ecosystem                                                |
| 37  | Oneof JSON                 | Delegated to `protobuf-elixir`                         | Matches generated module metadata behavior without custom transformation logic  |
| 38  | Type mismatch              | Raise at encode time                                   | Clear error message, returns `internal` to client                              |
| 39  | Request logging            | `:debug` level                                         | Invisible in prod, useful in dev                                               |
| 40  | Plug compatibility         | Connect protocol is Plug-native                        | Connect uses HTTP/1.1 request/response semantics, not HTTP/2 streams           |
| 41  | Streaming backpressure     | Fire-and-forget via `Plug.Conn.chunk/2`                | TCP-level backpressure sufficient; same approach as Phoenix LiveView           |
| 42  | Streaming trailers         | Envelope-only (no HTTP trailers)                       | Plug has no trailer API; envelope framing works on all adapters                |
| 43  | HTTP/2 conformance testing | HTTP/1.1 only for v0.1.0                               | Plug abstracts protocol differences; add HTTP/2 testing with streaming         |
| 44  | Body parser detection      | Runtime check + documentation                          | Detect consumed body and raise clear error; prevents debugging pain            |
| 45  | Handler context            | Raw `Plug.Conn` for v0.1.0                             | Familiar to Phoenix devs; context struct considered for future                 |
| 46  | Codec extensibility        | Public `ConnectRPC.Codec` behaviour                    | Low cost, future-proof; proto + json ship as built-in implementations          |
| 47  | Codec registration         | Init-time, explicit replacement                        | User-provided `codecs:` list fully replaces defaults; no implicit merge        |
| 48  | Error detail type          | Require `full_name/0`, raise if missing                | Ensures correct protobuf type URLs; no silent wrong behavior                   |
| 49  | Error correlation          | User's responsibility                                  | Plug.RequestId / OpenTelemetry are opt-in; library doesn't assume strategy     |
| 50  | Response headers/trailers  | Experimental 3-tuple return in v0.1.0                  | Useful and conformance-aligned; metadata shape may evolve                      |
| 51  | Double-send detection      | Check `conn.state` after handler, raise if `:sent`     | Prevents silent failures when handler calls `send_resp/3` directly             |
| 52  | Proto2 support             | Best-effort, no validation                             | protobuf-elixir handles both; JSON codec may not perfectly follow proto2 rules |
| 53  | Reverse proxy paths        | User's infrastructure concern                          | `forward/3` + proxy config handle path stripping; not library's job            |
| 54  | Decode error verbosity     | Always sanitized                                       | "Invalid request body" regardless of cause; no information leakage             |
| 55  | Content-Length validation  | Delegate to adapter                                    | Bandit/Cowboy validate at HTTP level; double-checking adds no value            |
| 56  | Handler timeout            | Deferred with Connect-Timeout-Ms                       | Adapter idle timeouts sufficient for v0.1.0; avoid timeout layer confusion     |
| 57  | Unknown JSON fields        | Delegate to protobuf-elixir                            | Whatever protobuf-elixir does, we pass through; not our abstraction            |
| 58  | Message size limits        | `Plug.Conn.read_body/2` limits only                    | No additional library-level limit; users configure via `read_body_opts`        |
| 59  | Response codec             | Always mirrors request codec                           | Simple, predictable, spec-aligned; no Accept header negotiation                |
| 60  | Protobuf dep version       | `~> 0.15`                                              | Requires `full_name/0` for error detail encoding; aligns with detail type requirement |
| 61  | Telemetry codec field      | Media type string                                      | `codec: "application/json"` instead of atom; consistent with custom codecs     |
| 62  | Detail encoding failure    | Fall back to internal error                            | Log failure, return generic internal error; never send partially-encoded details |
| 63  | Codec encode API           | Struct alone is sufficient                             | No need for extra context; codec receives the response struct only             |
| 64  | Exception types            | Keep RuntimeError                                      | No custom exception types for internal library errors; RuntimeError is clear   |
| 65  | Init validation            | Validate codecs at init time                           | Check `media_type/0`, `encode/1`, `decode/2` exports; fail fast at startup    |
| 66  | Before-send guard          | Safe from false positives                              | Library's own `send_error` never triggers the double-send detection            |
| 67  | Hexdocs scope              | Public modules + key functions only                    | ConnectRPC, Error, Handler, Codec, Codec.JSON, Codec.Proto documented          |
