defmodule Connect.Envelope do
  @moduledoc """
  ConnectRPC envelope framing.

  Each envelope frame is: `[flags:1 byte] [length:4 bytes big-endian] [payload:length bytes]`

  Flag bits:
    - Bit 0 (0x01): compressed
    - Bit 1 (0x02): end-stream
    - Bits 2-7: reserved (must be zero)
  """

  @flag_compressed 0x01
  @flag_end_stream 0x02

  @doc "Wraps a data payload in an uncompressed envelope frame."
  @spec wrap_data(binary()) :: binary()
  def wrap_data(payload) do
    <<0x00, byte_size(payload)::32, payload::binary>>
  end

  @doc "Wraps an EndStream JSON payload in an envelope frame."
  @spec wrap_end(map()) :: binary()
  def wrap_end(metadata \\ %{}) do
    json = Jason.encode!(metadata)
    <<@flag_end_stream, byte_size(json)::32, json::binary>>
  end

  @doc """
  Decodes a single envelope frame from the beginning of a binary.

  Returns `{:ok, frame, rest}` or `{:error, reason}`.
  """
  @spec decode_frame(binary()) ::
          {:ok, %{compressed?: boolean(), end_stream?: boolean(), payload: binary()}, binary()}
          | {:error, atom()}
  def decode_frame(<<flags::8, length::32, rest::binary>>) when byte_size(rest) >= length do
    reserved_bits = flags |> Bitwise.band(0xFC)

    if reserved_bits != 0 do
      {:error, :reserved_bits_set}
    else
      <<payload::binary-size(length), remaining::binary>> = rest

      frame = %{
        compressed?: Bitwise.band(flags, @flag_compressed) != 0,
        end_stream?: Bitwise.band(flags, @flag_end_stream) != 0,
        payload: payload
      }

      {:ok, frame, remaining}
    end
  end

  def decode_frame(<<_flags::8, _length::32, _rest::binary>>), do: {:error, :incomplete_frame}
  def decode_frame(_), do: {:error, :invalid_frame}
end
