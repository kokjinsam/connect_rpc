defmodule Connect.Protocol do
  @moduledoc """
  Content-type parsing and wire mode classification for the Connect protocol.
  """

  @type codec :: :json | :binary
  @type wire_mode :: :unary | :streaming

  @doc """
  Parses the `content-type` header and returns the wire mode and codec.

  Strips parameters like `; charset=utf-8` before matching.

  Returns `{:ok, %{wire_mode: wire_mode, codec: codec}}` or
  `{:error, :unsupported_media_type}`.
  """
  @spec parse_content_type(Plug.Conn.t()) ::
          {:ok, %{wire_mode: wire_mode(), codec: codec()}} | {:error, :unsupported_media_type}
  def parse_content_type(conn) do
    conn
    |> Plug.Conn.get_req_header("content-type")
    |> List.first("")
    |> String.split(";")
    |> hd()
    |> String.trim()
    |> classify()
  end

  defp classify("application/json"), do: {:ok, %{wire_mode: :unary, codec: :json}}
  defp classify("application/proto"), do: {:ok, %{wire_mode: :unary, codec: :binary}}
  defp classify("application/connect+json"), do: {:ok, %{wire_mode: :streaming, codec: :json}}
  defp classify("application/connect+proto"), do: {:ok, %{wire_mode: :streaming, codec: :binary}}
  defp classify(_), do: {:error, :unsupported_media_type}

  @doc "Returns the MIME type for unary responses."
  @spec mime_type(codec()) :: String.t()
  def mime_type(:json), do: "application/json"
  def mime_type(:binary), do: "application/proto"

  @doc "Returns the MIME type for streaming responses."
  @spec stream_mime_type(codec()) :: String.t()
  def stream_mime_type(:json), do: "application/connect+json"
  def stream_mime_type(:binary), do: "application/connect+proto"
end
