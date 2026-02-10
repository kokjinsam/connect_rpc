defmodule Connect.Stream do
  @moduledoc """
  Streaming state for ConnectRPC server-streaming responses.

  Wraps a `Plug.Conn` (already in chunked mode) and a codec.
  Each `send/2` call encodes the data, wraps it in an envelope frame,
  and writes the chunk to the connection.
  """

  defstruct [:conn, :codec]

  @type t :: %__MODULE__{
          conn: Plug.Conn.t(),
          codec: :json | :binary
        }

  @spec new(Plug.Conn.t(), :json | :binary) :: t()
  def new(conn, codec), do: %__MODULE__{conn: conn, codec: codec}

  @doc """
  Sends a message on the stream.

  Encodes the data with the stream's codec, wraps it in an envelope,
  and writes it as a chunk. Returns `{:ok, updated_stream}` or `{:error, reason}`.
  """
  @spec send(t(), struct()) :: {:ok, t()} | {:error, term()}
  def send(%__MODULE__{conn: conn, codec: codec} = stream, data) do
    encoded = Connect.Codec.encode(data, codec)
    envelope = Connect.Envelope.wrap_data(encoded)

    case Plug.Conn.chunk(conn, envelope) do
      {:ok, new_conn} -> {:ok, %{stream | conn: new_conn}}
      {:error, reason} -> {:error, reason}
    end
  end
end
