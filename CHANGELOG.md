# Changelog

## 0.3.0

- Breaking: changed handler callback signature from `(conn, request)` to `(request, context)`
- Added `ConnectRPC.Context` plus `ConnectRPC.Context.put/3` and `ConnectRPC.Context.get/3` for per-request handler context
- Added automatic context initialization via `ConnectRPC.Plug.Context` in `service` pipelines
- Removed handler double-send guard logic by eliminating direct `Plug.Conn` access in handler callbacks
- Added context propagation tests and updated conformance handler wiring to source request info from context

## 0.2.0

- Refactored request handling into focused modules: `ConnectRPC.Plug.Codec`, `ConnectRPC.Plug.Decoder`, and `ConnectRPC.Plug.Validator`
- Added `ConnectRPC.Router` and updated handler wiring for clearer route/service composition
- Improved metadata handling in protocol parsing and request decoding
- Expanded test coverage with dedicated plug and router tests, plus updated handler/protocol integration tests
- Added and restructured the `examples/greeter` Phoenix app to demonstrate ConnectRPC integration end-to-end
- Simplified conformance runtime wiring by removing unused conformance Plug/Service modules and routing through the new structure
- Updated README quick-start and service implementation docs for the v0.2.0 API shape
- Fixed codec validation to use `Code.ensure_compiled/1` in `validate_codec!/1`

## 0.1.0

- Initial ConnectRPC Plug implementation for unary RPCs
- Handler macro with compile-time handler validation
- Proto and JSON codecs
- Protocol validation and Connect JSON error formatting
- Telemetry emission for handler lifecycle events
- ExUnit coverage for protocol, codecs, handler macro, and request flow
- CI quality gates for formatting, warnings-as-errors compile, ExUnit, known-failing guard, and conformance
