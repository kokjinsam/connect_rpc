defmodule GreeterExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GreeterExampleWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:greeter_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GreeterExample.PubSub},
      # Start a worker by calling: GreeterExample.Worker.start_link(arg)
      # {GreeterExample.Worker, arg},
      # Start to serve requests, typically the last entry
      GreeterExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GreeterExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GreeterExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
