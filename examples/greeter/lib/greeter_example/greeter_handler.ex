defmodule GreeterExample.GreeterHandler do
  @moduledoc false

  use ConnectRPC.Handler

  alias GreeterExample.Gen.GreetRequest
  alias GreeterExample.Gen.GreetResponse

  def greet(%GreetRequest{name: name}, _context) do
    {:ok, %GreetResponse{greeting: "Hello, #{name}!"}}
  end
end
