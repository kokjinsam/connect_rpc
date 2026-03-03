defmodule ConnectRPC.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/YOUR_ORG/connect_rpc"

  def project do
    [
      app: :connect_rpc,
      version: @version,
      elixir: "~> 1.19",
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
      "test/support/conformance/runtime",
      "test/support/conformance/gen"
    ]
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:protobuf, "~> 0.14"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:bandit, "~> 1.7", only: :test}
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
