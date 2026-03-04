defmodule GreeterExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :greeter_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {GreeterExample.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:connect_rpc, path: "../.."},
      {:phoenix, "~> 1.7"},
      {:plug_cowboy, "~> 2.7"},
      {:protobuf, "~> 0.15"},
      {:jason, "~> 1.4"}
    ]
  end
end
