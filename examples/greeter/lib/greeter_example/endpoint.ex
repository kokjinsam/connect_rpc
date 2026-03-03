defmodule GreeterExample.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :greeter_example

  plug(GreeterExample.Router)
end
