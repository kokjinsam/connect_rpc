defmodule Connect.Envelope.Reader do
  @moduledoc """
  Reads and validates ConnectRPC envelope frames from a binary stream.

  Enforces:
  - Reserved bits must be zero
  - Max message size per frame
  - End-stream must be the terminal frame
  - No extra bytes after end-stream
  - Compressed frames detected (flag returned; decompression is external)
  """

  import Bitwise

  @flag_compressed 0x01
  @flag_end_stream 0x02
  @reserved_mask 0xFC

  @type frame :: %{
          compressed?: boolean(),
          end_stream?: boolean(),
          payload: binary()
        }

  @type read_opts :: [max_bytes: pos_integer()]

  @doc """
  Decodes a single envelope frame from the beginning of a binary buffer.

  Returns `{:ok, frame, remaining_bytes}` or `{:error, reason}`.

  ## Options

    * `:max_bytes` - maximum allowed payload size per frame
  """
  @spec decode_frame(binary(), read_opts()) ::
          {:ok, frame(), binary()} | {:error, atom()}
  def decode_frame(data, opts \\ [])

  def decode_frame(<<flags::8, length::32, rest::binary>>, opts)
      when byte_size(rest) >= length do
    max_bytes = Keyword.get(opts, :max_bytes)

    cond do
      band(flags, @reserved_mask) != 0 ->
        {:error, :reserved_bits_set}

      max_bytes != nil and length > max_bytes ->
        {:error, :message_too_large}

      true ->
        <<payload::binary-size(length), remaining::binary>> = rest

        frame = %{
          compressed?: band(flags, @flag_compressed) != 0,
          end_stream?: band(flags, @flag_end_stream) != 0,
          payload: payload
        }

        {:ok, frame, remaining}
    end
  end

  def decode_frame(<<_flags::8, _length::32, _rest::binary>>, _opts),
    do: {:error, :incomplete_frame}

  def decode_frame(<<>>, _opts), do: {:error, :empty_buffer}

  def decode_frame(data, _opts) when byte_size(data) < 5,
    do: {:error, :incomplete_header}

  @doc """
  Reads all frames from a binary buffer, validating stream structure.

  Returns `{:ok, data_frames, end_stream_frame | nil}` where:
  - `data_frames` is a list of frame maps (excluding end-stream)
  - `end_stream_frame` is the parsed end-stream frame, or nil

  Rejects:
  - Extra bytes after end-stream (protocol corruption)
  - Reserved bits on any frame
  - Frames exceeding `:max_bytes`
  """
  @spec read_all(binary(), read_opts()) ::
          {:ok, [frame()], frame() | nil} | {:error, atom()}
  def read_all(data, opts \\ [])

  def read_all(<<>>, _opts), do: {:ok, [], nil}

  def read_all(data, opts) when is_binary(data) do
    read_all_loop(data, opts, [])
  end

  defp read_all_loop(<<>>, _opts, acc) do
    {:ok, Enum.reverse(acc), nil}
  end

  defp read_all_loop(data, opts, acc) do
    case decode_frame(data, opts) do
      {:ok, %{end_stream?: true} = frame, remaining} ->
        if remaining == <<>> do
          {:ok, Enum.reverse(acc), frame}
        else
          {:error, :extra_bytes_after_end_stream}
        end

      {:ok, %{end_stream?: false} = frame, remaining} ->
        read_all_loop(remaining, opts, [frame | acc])

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Reads exactly one data frame from the buffer, enforcing unary cardinality.

  Used for streaming requests where the client sends a single message
  in an envelope frame (e.g., server-streaming RPC input).

  Validates:
  - First frame is not end-stream
  - First frame is not compressed (compression not yet supported)
  - No second data frame follows (cardinality = 1)
  - Optional end-stream after the data frame is accepted
  - No extra bytes after end-stream

  Returns `{:ok, payload, end_stream_frame | nil}` or `{:error, reason}`.
  """
  @spec read_single_message(binary(), read_opts()) ::
          {:ok, binary(), frame() | nil} | {:error, atom()}
  def read_single_message(data, opts \\ []) do
    case decode_frame(data, opts) do
      {:ok, %{end_stream?: true}, _remaining} ->
        {:error, :unexpected_end_stream}

      {:ok, %{compressed?: true}, _remaining} ->
        {:error, :compression_not_supported}

      {:ok, %{end_stream?: false, compressed?: false, payload: payload}, remaining} ->
        validate_after_single_message(payload, remaining, opts)

      {:error, _} = err ->
        err
    end
  end

  defp validate_after_single_message(payload, <<>>, _opts) do
    {:ok, payload, nil}
  end

  defp validate_after_single_message(payload, remaining, opts) do
    case decode_frame(remaining, opts) do
      {:ok, %{end_stream?: true} = end_frame, extra} ->
        if extra == <<>> do
          {:ok, payload, end_frame}
        else
          {:error, :extra_bytes_after_end_stream}
        end

      {:ok, %{end_stream?: false}, _} ->
        {:error, :multiple_messages_in_unary}

      {:error, _} = err ->
        err
    end
  end
end
