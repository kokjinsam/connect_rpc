defmodule ConnectRPC.Conformance.Endpoint do
  @moduledoc false

  use Plug.Builder

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, ConnectRPC.Parser, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(ConnectRPC.Conformance.Router)
end
