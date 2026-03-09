# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

config :greeter_example,
  generators: [timestamp_type: :utc_datetime]

config :greeter_example, GreeterExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: GreeterExampleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GreeterExample.PubSub,
  live_view: [signing_salt: "x45j4bTi"]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
