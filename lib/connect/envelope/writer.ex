defmodule Connect.Envelope.Writer do
  @moduledoc """
  Writes ConnectRPC envelope frames.

  Each frame: `[flags:1 byte] [length:4 bytes big-endian] [payload:N bytes]`

  Flag bits:
    - Bit 0 (0x01): compressed
    - Bit 1 (0x02): end-stream
    - Bits 2-7: reserved (must be zero)
  """

  @flag_compressed 0x01
  @flag_end_stream 0x02

  @doc "Wraps a data payload in an uncompressed envelope frame."
  @spec data(binary()) :: binary()
  def data(payload) when is_binary(payload) do
    <<0x00, byte_size(payload)::32, payload::binary>>
  end

  @doc """
  Wraps a data payload in a compressed envelope frame.

  The caller is responsible for actually compressing the payload;
  this only sets the compression flag in the frame header.
  """
  @spec data_compressed(binary()) :: binary()
  def data_compressed(payload) when is_binary(payload) do
    <<@flag_compressed, byte_size(payload)::32, payload::binary>>
  end

  @doc """
  Wraps an EndStream JSON payload in an envelope frame with the
  end-stream flag set.
  """
  @spec end_stream(map()) :: binary()
  def end_stream(metadata \\ %{}) do
    json = Jason.encode!(metadata)
    <<@flag_end_stream, byte_size(json)::32, json::binary>>
  end
end
