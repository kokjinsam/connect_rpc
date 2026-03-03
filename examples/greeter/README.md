# Greeter Example

Minimal ConnectRPC greeter built with `connect_rpc`.

## Run

```bash
cd examples/greeter
mix deps.get
mix phx.server
```

Server listens on `http://localhost:4001` by default. Set `PORT` to override.

## Request

```bash
curl -X POST http://localhost:4001/connectrpc.greet.v1.GreeterService/Say \
  -H "Content-Type: application/json" \
  -H "Connect-Protocol-Version: 1" \
  -d '{"name":"Sam"}'
```

Expected response:

```json
{"greeting":"Hello, Sam!"}
```
