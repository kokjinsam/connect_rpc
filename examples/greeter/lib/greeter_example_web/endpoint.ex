defmodule GreeterExampleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :greeter_example

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart],
    pass: ["*/*"]

  plug Plug.MethodOverride
  plug Plug.Head
  plug GreeterExampleWeb.Router
end
