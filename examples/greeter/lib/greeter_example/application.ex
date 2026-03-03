defmodule GreeterExample.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: GreeterExample.PubSub},
      {GreeterExample.Endpoint, [http: [port: port()]]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: GreeterExample.Supervisor)
  end

  defp port do
    System.get_env("PORT", "4001")
    |> String.to_integer()
  end
end
