# ConnectRPC for Elixir — Technical Intent

**Package**: `connect_rpc` (Hex)
**Module namespace**: `ConnectRPC`
**Version**: 0.1.0
**License**: MIT
**Minimum**: Elixir 1.14+ / OTP 25+
**Status**: Target specification for planned v0.1.0 behavior. The current repository may not yet implement everything below.

---

## 1. Overview

`connect_rpc` targets an Elixir library that will implement a **ConnectRPC-compatible server** as a Plug, designed to work inside Phoenix.Router or Plug.Router, running under Bandit or Cowboy.

v0.1.0 targets support for the Connect protocol (not gRPC or gRPC-Web) for **unary RPCs**, with streaming deferred to a future release.

Users will generate Elixir protobuf modules from `.proto` files using `protobuf-elixir`, then define handler modules that implement RPC methods as plain Elixir functions.

---

## 2. Dependencies

| Dependency                   | Type | Purpose                                 |
| ---------------------------- | ---- | --------------------------------------- |
| `plug`                       | Hard | HTTP abstraction, Plug behavior         |
| `jason`                      | Hard | JSON encoding/decoding                  |
| `protobuf` (protobuf-elixir) | Hard | Protobuf encoding/decoding, descriptors |
| `telemetry`                  | Hard | Observability events                    |

No other runtime dependencies. No optional runtime deps in v0.1.0 (dev/test deps are expected).

---

## 3. Module Structure (Public API)

```
ConnectRPC              — Top-level Plug. Mounted per-service in a router.
ConnectRPC.Handler      — `use` macro for defining service handler modules.
ConnectRPC.Error        — Connect error struct (code, message, details).
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

Users define handler modules using a macro that introspects the generated protobuf service descriptor:

```elixir
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

1. Calls `Module.ensure_compiled(service_module)` to verify the protobuf service module exists. If not compiled yet, raises a clear compile error:

   > `"Module MyApp.Proto.ConnectRPC.Greet.V1.GreetService must be compiled before MyApp.GreetHandler. Ensure your .proto-generated modules are in a directory that compiles before your handler modules (e.g., lib/proto/ compiles before lib/handlers/)."`

2. Reads the service descriptor from the protobuf module to extract:
   - Service fully-qualified name (e.g., `connectrpc.greet.v1.GreetService`)
   - RPC method names, request types, response types, and stream types

3. **Compile-time validation**: Checks that the handler module defines a function for each unary RPC method in the service descriptor. Missing methods raise a compile error:

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

### 4.3 Streaming Preparation

In v0.1.0, only unary RPCs are supported. The macro will skip non-unary methods (server streaming, client streaming, bidi) with a compile-time info message:

> `"Skipping streaming method ServerGreet — streaming is not yet supported in connect_rpc v0.1.0"`

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
2. **Protocol header validation** (strict): Verify `Connect-Protocol-Version: 1` header is present. If missing, return Connect error `invalid_argument`:
   > `"Missing required Connect-Protocol-Version header"`
3. **Content-type negotiation**: Parse the `Content-Type` media type (ignoring optional parameters such as `charset=utf-8`):
   - `application/proto` → Protobuf binary codec
   - `application/json` → Proto3 JSON codec
   - Anything else → HTTP **415** with a JSON-encoded Connect error body (`code: "invalid_argument"`, `message: "Unsupported content type: <type>"`)
4. **Compression check**: If `Content-Encoding` header is present and not `identity`, return Connect error `unimplemented`:
   > `"Compression is not supported"`
5. **Body reading**: Read the request body via `Plug.Conn.read_body/2` in a loop until completion (`{:more, chunk, conn}` then `{:ok, chunk, conn}`), using the library's default `read_body` limits/options.
   - Request size/time behavior is dictated by the configured/default `Plug.Conn.read_body/2` options used by `ConnectRPC`.
   - On Connect routes, request body ownership must remain with `ConnectRPC` (upstream body parsers should not consume Connect RPC bodies before this step).
   - If body reading returns `{:error, :too_large}`, return HTTP **413** with Connect error `resource_exhausted` and message `"Request body too large"`.
   - If body reading returns `{:error, :timeout}`, return HTTP **504** with Connect error `deadline_exceeded` and message `"Request body read timed out"`.
   - For any other body-read error (`{:error, reason}`), return HTTP **500** with Connect error `internal` and message `"Failed to read request body"`.
6. **Decoding**: Decode the body using the negotiated codec into the expected request struct.
   - If decoding fails (invalid JSON or protobuf payload), return HTTP **400** with Connect error `invalid_argument` and message `"Invalid request body"`.
7. **Handler invocation**: Call `handler_module.method_name(request_struct, conn)`.
8. **Response encoding**: Encode the response struct using the same codec as the request.
9. **Type check at encode time**: If the handler returns a value that is not the expected response struct type, raise a clear error and return Connect `internal` error to the client:
   > `"Expected %MyApp.Proto.ConnectRPC.Greet.V1.GreetResponse{}, got %{foo: \"bar\"}"`
10. **Response**: Send HTTP 200 with:
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

v0.1.0 supports **no Connect-level compression handling**. If a request includes a `Content-Encoding` header with any value other than `identity`, the library returns:

- Connect error code: `unimplemented`
- Message: `"Compression is not supported"`

No Connect-level `Accept-Encoding` negotiation or compressed envelope handling is implemented.

HTTP-layer response compression (if any) is outside `connect_rpc` protocol logic and controlled by user-selected server/middleware configuration.

### 6.5 Streaming Envelope Framing (Architecture Note)

Although streaming is deferred, the internal architecture documents the frame format for future implementation:

```
frame = <flags:uint8> <length:uint32be> <message:bytes>
```

- `flags`: Bit 0 = compressed, Bit 1 = end-of-stream (trailers frame), Bits 2-7 = reserved
- `length`: 4-byte big-endian unsigned integer, byte length of `message`
- `message`: Protobuf or JSON encoded message bytes

This is NOT used for unary RPCs (which use simple request/response bodies).

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
    details: [struct()]
  }

  defexception code: :unknown, message: "", details: []
end
```

- `code` — One of the 16 standard Connect error codes (as atoms)
- `message` — Human-readable error message
- `details` — List of protobuf structs (e.g., `Google.Rpc.BadRequest`). Serialized as `{"type": "<fully-qualified message name>", "value": "<base64>"}` in the wire format. Default: `[]`

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

### 8.1 Protobuf Binary Codec (`ConnectRPC.Codec.Proto`)

- Content-Type: `application/proto`
- Encoding: Delegates to `protobuf-elixir`'s `Module.encode/1` and `Module.decode/2`
- Straightforward pass-through to the generated protobuf modules

### 8.2 Proto3 JSON Codec (`ConnectRPC.Codec.JSON`)

- Content-Type: `application/json`
- Built in-library using `protobuf-elixir` descriptors + `Jason`
- Implements the proto3 canonical JSON mapping

#### 8.2.1 Field Name Mapping

- Proto field names are converted to **lowerCamelCase** in JSON output
- Both the original proto field name and lowerCamelCase are accepted on input (per spec)

#### 8.2.2 Default Value Omission

- Fields set to their proto3 default values (0, "", false, empty list, nil) are **omitted** from JSON output
- This follows the proto3 JSON spec recommendation ("SHOULD omit")

#### 8.2.3 Oneof Fields

- `protobuf-elixir` represents oneofs as `{:field_name, value}` tuples
- The JSON codec auto-handles this: inspects the descriptor, recognizes oneof fields, and correctly serializes/deserializes to/from the flat JSON representation
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
| `google.protobuf.Int64Value`  | String (to avoid JS precision loss) or null |
| `google.protobuf.UInt64Value` | String or null                              |
| `google.protobuf.Int32Value`  | Number or null                              |
| `google.protobuf.UInt32Value` | Number or null                              |
| `google.protobuf.BoolValue`   | Boolean or null                             |
| `google.protobuf.StringValue` | String or null                              |
| `google.protobuf.BytesValue`  | Base64 string or null                       |
| `google.protobuf.Empty`       | Empty JSON object (`{}`)                    |

**NOT supported in v0.1.0** (will serialize as regular proto messages):

- `google.protobuf.Struct` / `Value` / `ListValue`
- `google.protobuf.Any`
- `google.protobuf.FieldMask`

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
  codec: :proto | :json,
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
  codec: :proto | :json,
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
  codec: :proto | :json,
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
[debug] ConnectRPC connectrpc.greet.v1.GreetService/Greet codec=json duration=1.2ms status=ok
```

Errors (handler crashes, codec failures) are logged at `:error` level with full stacktraces.

---

## 10. Content-Type Negotiation

### 10.1 Request Content-Type

| Content-Type        | Codec Used                         |
| ------------------- | ---------------------------------- |
| `application/proto` | `ConnectRPC.Codec.Proto`           |
| `application/json`  | `ConnectRPC.Codec.JSON`            |
| Anything else       | HTTP 415 + Connect error JSON body |

Media-type parameters are ignored during negotiation. For example, `application/json; charset=utf-8` is treated as `application/json`.

### 10.2 Response Content-Type

The response content-type mirrors the negotiated codec (not request parameters). JSON responses use `application/json`; protobuf responses use `application/proto`.

### 10.3 Error Responses

Error responses are **always JSON** (`Content-Type: application/json`), regardless of the request content-type. This matches the Connect protocol spec.

---

## 11. Protocol Validation (Strict Mode)

The library enforces strict Connect protocol compliance:

1. **HTTP method**: Only `POST` is accepted for unary RPCs. Other methods return HTTP 405 Method Not Allowed.
2. **Connect-Protocol-Version header**: Must be present with value `1`. Missing or wrong value returns Connect error `invalid_argument`.
3. **Content-Type header**: Media type must be `application/proto` or `application/json` (parameters are allowed). Others return HTTP 415.
4. **Content-Encoding**: If present and not `identity`, returns Connect error `unimplemented`.

### 11.1 gRPC / gRPC-Web

No special handling for `application/grpc` or `application/grpc-web` content types. They will fail content-type negotiation like any other unsupported type (HTTP 415).

### 11.2 Body Parser Ownership

For Connect routes, endpoint/body parser configuration must not consume Connect request bodies before `ConnectRPC` handles them. This keeps decoding and Connect error formatting in one place and prevents non-Connect parser errors from being returned on Connect endpoints.

`ConnectRPC` is responsible for reading Connect request bodies and mapping body-read failures (for example, `:too_large`, `:timeout`) into Connect-formatted error responses.

If a hard upstream limit (adapter/server/other middleware) rejects the request before it reaches `ConnectRPC`, the response may not be Connect-formatted.

---

## 12. Deferred Features (Not in v0.1.0)

The following features are explicitly deferred and will not be in the initial release:

| Feature                                          | Notes                                                |
| ------------------------------------------------ | ---------------------------------------------------- |
| **Server streaming**                             | Requires chunked transfer encoding, envelope framing |
| **Client streaming**                             | Requires request body chunk reading                  |
| **Bidirectional streaming**                      | Requires both of the above                           |
| **GET requests for idempotent RPCs**             | Query param encoding, base64url message              |
| **Interceptors**                                 | Typed middleware wrapping RPC calls                  |
| **Connect-Timeout-Ms**                           | Deadline propagation and enforcement                 |
| **Connect-level compression (gzip)**             | Compression negotiation + compressed envelope framing |
| **Custom response headers/trailers**             | Handler-set response metadata                        |
| **Test helpers**                                 | `ConnectRPC.Test` module for handler unit testing    |
| **Health check**                                 | No built-in health endpoint                          |
| **CORS Plug**                                    | Documented but not implemented                       |
| **Well-known types: Struct/Value/Any/FieldMask** | Only core types supported                            |
| **Runtime introspection**                        | No `__connect_rpc__/1` function                      |

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

The v0.1.0 target repository structure includes a working example Phoenix application at `examples/greeter/`:

```
examples/greeter/
├── mix.exs
├── priv/
│   └── proto/
│       └── greet.proto
├── lib/
│   ├── greeter/
│   │   ├── application.ex
│   │   ├── proto/          # Generated protobuf modules
│   │   │   └── ...
│   │   ├── greet_handler.ex
│   │   └── router.ex
│   └── greeter.ex
└── test/
    └── greeter_test.exs
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

This provides strong protocol correctness guarantees and catches edge cases that hand-written tests might miss.

---

## 17. Project Structure

Target layout for the v0.1.0 release:

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
│       ├── proto/            # Test .proto files
│       └── test_handlers.ex  # Test handler modules
└── examples/
    └── greeter/              # Example Phoenix app
```

---

## 18. mix.exs

```elixir
defmodule ConnectRPC.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/YOUR_ORG/connect_rpc" # Replace before release

  def project do
    [
      app: :connect_rpc,
      version: @version,
      elixir: "~> 1.14",
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
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:protobuf, "~> 0.12"},
      {:telemetry, "~> 1.0"},
      # Dev/test
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.6", only: :test},
      {:bandit, "~> 1.0", only: :test}
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

| #   | Decision                   | Choice                                                 | Rationale                                                              |
| --- | -------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| 1   | Service definition         | Macro-based DSL                                        | Less boilerplate, auto-discovers methods from proto descriptors        |
| 2   | Protobuf library           | protobuf-elixir                                        | Most maintained, has descriptor support                                |
| 3   | GET for idempotent RPCs    | Deferred                                               | Simplifies v0.1.0, addable without breaking changes                    |
| 4   | Interceptors               | Deferred                                               | Users can use Plug middleware; typed interceptors with streaming       |
| 5   | JSON codec                 | Built in-library                                       | Ensures correctness of proto3 JSON mapping                             |
| 6   | Error API                  | Custom exception struct                                | `%ConnectRPC.Error{code, message, details}` — raiseable and returnable |
| 7   | Unexpected exceptions      | Sanitize by default + opt-in debug message             | Secure-by-default; raw exception messages available in dev/test        |
| 8   | Timeout handling           | Deferred                                               | Most users won't need server-side deadline enforcement initially       |
| 9   | Routing                    | Single mount per service                               | Clean, minimal router config via `forward`                             |
| 10  | Protocol header validation | Strict                                                 | Spec-compliant; rejects non-Connect traffic                            |
| 11  | Package name               | `connect_rpc` / `ConnectRPC`                           | Clear, maps to protocol name                                           |
| 12  | gRPC content types         | No special handling                                    | Fail naturally via content-type negotiation                            |
| 13  | Handler signature          | `method(request, conn) → {:ok, resp} \| {:error, err}` | Full HTTP access, familiar to Phoenix devs                             |
| 14  | Response metadata          | Deferred                                               | Simplifies handler signature for v0.1.0                                |
| 15  | Conformance tests          | CI from day one                                        | Gold standard for protocol correctness                                 |
| 16  | Test helpers               | Deferred                                               | Ship based on user feedback                                            |
| 17  | JSON well-known types      | Core types only                                        | Timestamp, Duration, wrappers cover 90% of use cases                   |
| 18  | JSON default omission      | Omit defaults                                          | Spec-recommended, smaller payloads                                     |
| 19  | Content-type errors        | HTTP 415 + Connect error JSON body                     | Both HTTP semantics and Connect error format                           |
| 20  | Concurrency controls       | None                                                   | Delegate to Bandit/Cowboy; each request is a process                   |
| 21  | CORS                       | Userland only                                          | Users choose and configure their own CORS stack/policy                 |
| 22  | Compile-time validation    | Yes                                                    | Catches missing handlers early; clear error messages                   |
| 23  | Elixir/OTP version         | 1.14+ / OTP 25+                                        | ~2 year support window, broad compatibility                            |
| 24  | Body size limits           | `Plug.Conn.read_body/2` defaults                       | Predictable defaults with explicit opt-in override behavior             |
| 25  | Compression                | No Connect-level handling                              | Reject non-identity request encoding with `unimplemented`               |
| 26  | Dependencies               | plug + jason + protobuf + telemetry                    | Minimal but includes observability from day one                        |
| 27  | Telemetry naming           | `[:connect_rpc, :handler, :start/stop/exception]`      | Matches Phoenix convention                                             |
| 28  | Introspection function     | None                                                   | Proto module already has descriptors                                   |
| 29  | Unknown method error       | `unimplemented`                                        | Matches connect-go and gRPC semantics                                  |
| 30  | Handler callbacks          | Method-name functions (snake_case)                     | Most Elixir-idiomatic, one function per RPC                            |
| 31  | Compile order              | `Module.ensure_compiled` + clear error                 | Catches issues at compile time with helpful messages                   |
| 32  | Health check               | None                                                   | Application-level concern                                              |
| 33  | Module structure           | Flat namespace                                         | Simple, discoverable public API                                        |
| 34  | Initial version            | 0.1.0                                                  | Signals early development, no stability promises                       |
| 35  | Example app                | Planned in-repo at `examples/greeter/`                 | Clone-and-run documentation                                            |
| 36  | License                    | MIT                                                    | Most common in Elixir ecosystem                                        |
| 37  | Oneof JSON                 | Auto-handle via descriptors                            | Correct proto3 JSON serialization                                      |
| 38  | Type mismatch              | Raise at encode time                                   | Clear error message, returns `internal` to client                      |
| 39  | Request logging            | `:debug` level                                         | Invisible in prod, useful in dev                                       |
