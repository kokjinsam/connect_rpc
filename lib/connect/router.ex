defmodule Connect.Router do
  @moduledoc """
  Provides a `connect_service` macro for mounting ConnectRPC services
  in a Phoenix router.

  ## Usage

      defmodule MyAppWeb.Router do
        use MyAppWeb, :router
        import Connect.Router

        scope "/api" do
          connect_service "/eliza.v1.ElizaService",
            service: Eliza.V1.ElizaService,
            impl: MyApp.Eliza.Server
        end
      end
  """

  defmacro connect_service(path, opts) do
    quote do
      forward unquote(path), Connect.Plug, unquote(opts)
    end
  end
end
