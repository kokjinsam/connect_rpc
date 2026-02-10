defmodule Connect.Service do
  @moduledoc """
  Macro for defining ConnectRPC service definitions.

  Generates `__rpc_calls__/0` returning 4-tuples compatible with the
  shape used by `grpc-elixir`:

      {name, {request_mod, request_stream?}, {response_mod, response_stream?}, opts}

  ## Usage

      defmodule Eliza.V1.ElizaService do
        use Connect.Service

        rpc :Say, Eliza.V1.SayRequest, Eliza.V1.SayResponse
        rpc :Introduce, Eliza.V1.SayRequest, Eliza.V1.SayResponse, stream: :response
      end
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :rpc_calls, accumulate: true)
      import Connect.Service, only: [rpc: 3, rpc: 4]
      @before_compile Connect.Service
    end
  end

  @doc """
  Defines an RPC method on the service.

  ## Options

    * `:stream` - streaming mode. One of `:response`, `:request`, or `:both`.
      Defaults to no streaming (unary).
  """
  defmacro rpc(name, request, response, opts \\ []) do
    stream = Keyword.get(opts, :stream)
    req_stream = stream in [:request, :both]
    resp_stream = stream in [:response, :both]

    quote do
      @rpc_calls {
        unquote(name),
        {unquote(request), unquote(req_stream)},
        {unquote(response), unquote(resp_stream)},
        %{}
      }
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __rpc_calls__, do: @rpc_calls
    end
  end
end
