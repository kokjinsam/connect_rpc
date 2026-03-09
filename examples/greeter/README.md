# Greeter Example (Phoenix + ConnectRPC)

This example is a fresh Phoenix app scaffolded with `mix phx.new` and wired to `connect_rpc`.
It is intentionally trimmed to be ConnectRPC-only (no browser page routes or UI assets).

## Run

```bash
cd examples/greeter
mix setup
mix phx.server
```

Server starts on `http://localhost:4000`.

## ConnectRPC Route

Service path:

- `/connectrpc.greet.v1.GreeterService/Greet`

Handler:

- `GreeterExample.GreeterHandler.greet/2`

Request/response modules:

- `GreeterExample.Gen.GreetRequest`
- `GreeterExample.Gen.GreetResponse`

## Test with JSON

```bash
curl -X POST http://localhost:4000/connectrpc.greet.v1.GreeterService/Greet \
  -H "Content-Type: application/json" \
  -H "Connect-Protocol-Version: 1" \
  -d '{"name":"World"}'
```

Expected response:

```json
{"greeting":"Hello, World!"}
```

## Proto Source

The proto schema is at `proto/greet.proto`.
