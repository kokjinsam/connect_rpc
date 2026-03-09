defmodule GreeterExample.GreeterHandler do
  @moduledoc false

  use ConnectRPC.Handler

  alias GreeterExample.Gen.GreetRequest
  alias GreeterExample.Gen.GreetResponse

  def greet(_conn, %GreetRequest{name: name}) do
    {:ok, %GreetResponse{greeting: "Hello, #{name}!"}}
  end
end
