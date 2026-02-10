defmodule Connect.BodyReader do
  @moduledoc """
  Custom body reader for `Plug.Parsers` that caches the raw request body.

  `Plug.Parsers` consumes `application/json` bodies before downstream plugs
  can read them. This module intercepts `read_body` and stores the raw bytes
  in `conn.private[:raw_body]` as iodata for efficient accumulation.

  ## Configuration

  In your endpoint:

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Phoenix.json_library(),
        body_reader: {Connect.BodyReader, :read_body, []}
  """

  @spec read_body(Plug.Conn.t(), keyword()) ::
          {:ok, binary(), Plug.Conn.t()}
          | {:more, binary(), Plug.Conn.t()}
          | {:error, term()}
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, body, cache_chunk(conn, body)}

      {:more, body, conn} ->
        {:more, body, cache_chunk(conn, body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp cache_chunk(conn, chunk) do
    existing = conn.private[:raw_body] || []
    Plug.Conn.put_private(conn, :raw_body, [existing | chunk])
  end
end
