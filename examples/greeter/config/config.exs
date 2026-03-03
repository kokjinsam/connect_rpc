import Config

config :greeter_example, GreeterExample.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: GreeterExample.ErrorJSON], layout: false],
  pubsub_server: GreeterExample.PubSub,
  secret_key_base: "nW6MNfFg4Kf8QWrhBk5Q1Qw2qpFOQriUMHB2zfymf43FlzG3n2DFs2mZr3dR8oHv"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
