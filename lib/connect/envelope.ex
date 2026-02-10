defmodule Connect.Envelope do
  @moduledoc """
  ConnectRPC envelope framing facade.

  Delegates to `Connect.Envelope.Writer` for frame construction
  and `Connect.Envelope.Reader` for frame parsing.

  Each envelope frame: `[flags:1 byte] [length:4 bytes big-endian] [payload:N bytes]`

  Flag bits:
    - Bit 0 (0x01): compressed
    - Bit 1 (0x02): end-stream
    - Bits 2-7: reserved (must be zero)
  """

  alias Connect.Envelope.{Reader, Writer}

  @doc "Wraps a data payload in an uncompressed envelope frame."
  @spec wrap_data(binary()) :: binary()
  def wrap_data(payload), do: Writer.data(payload)

  @doc "Wraps an EndStream JSON payload in an envelope frame."
  @spec wrap_end(map()) :: binary()
  def wrap_end(metadata \\ %{}), do: Writer.end_stream(metadata)

  @doc "Decodes a single envelope frame from the beginning of a binary."
  @spec decode_frame(binary(), keyword()) ::
          {:ok, Reader.frame(), binary()} | {:error, atom()}
  def decode_frame(data, opts \\ []), do: Reader.decode_frame(data, opts)
end
