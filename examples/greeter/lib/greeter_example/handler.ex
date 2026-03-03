defmodule GreeterExample.Handler do
  @moduledoc false

  use ConnectRPC.Handler, service: GreeterExample.Greet.V1.GreeterService

  alias GreeterExample.Greet.V1.{SayRequest, SayResponse}

  @spec say(SayRequest.t(), Plug.Conn.t()) :: {:ok, SayResponse.t()}
  def say(%SayRequest{name: name}, _conn) do
    target =
      case String.trim(name) do
        "" -> "World"
        value -> value
      end

    {:ok, %SayResponse{greeting: "Hello, #{target}!"}}
  end
end
