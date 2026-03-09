defmodule GreeterExampleWeb do
  @moduledoc """
  Web entrypoint for the Greeter example.
  """

  def static_paths, do: []

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: GreeterExampleWeb.Endpoint,
        router: GreeterExampleWeb.Router,
        statics: GreeterExampleWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/channel.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
