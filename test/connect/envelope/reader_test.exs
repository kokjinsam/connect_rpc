defmodule Connect.Envelope.ReaderTest do
  use ExUnit.Case, async: true

  alias Connect.Envelope.Reader

  # Helper to build a raw frame binary
  defp build_frame(flags, payload) do
    <<flags::8, byte_size(payload)::32, payload::binary>>
  end

  # --- decode_frame/2 ---

  describe "decode_frame/2" do
    test "decodes a normal data frame" do
      frame = build_frame(0x00, "hello")

      assert {:ok, %{compressed?: false, end_stream?: false, payload: "hello"}, <<>>} =
               Reader.decode_frame(frame)
    end

    test "decodes a compressed frame" do
      frame = build_frame(0x01, "data")
      assert {:ok, %{compressed?: true, end_stream?: false}, <<>>} = Reader.decode_frame(frame)
    end

    test "decodes an end-stream frame" do
      frame = build_frame(0x02, "{}")

      assert {:ok, %{end_stream?: true, compressed?: false, payload: "{}"}, <<>>} =
               Reader.decode_frame(frame)
    end

    test "decodes compressed end-stream frame" do
      frame = build_frame(0x03, "{}")

      assert {:ok, %{end_stream?: true, compressed?: true, payload: "{}"}, <<>>} =
               Reader.decode_frame(frame)
    end

    test "returns remaining bytes" do
      frame = build_frame(0x00, "hi") <> "extra"
      assert {:ok, %{payload: "hi"}, "extra"} = Reader.decode_frame(frame)
    end

    test "rejects reserved bits (bit 2)" do
      frame = build_frame(0x04, "data")
      assert {:error, :reserved_bits_set} = Reader.decode_frame(frame)
    end

    test "rejects reserved bits (bit 7)" do
      frame = build_frame(0x80, "data")
      assert {:error, :reserved_bits_set} = Reader.decode_frame(frame)
    end

    test "rejects frame exceeding max_bytes" do
      frame = build_frame(0x00, String.duplicate("x", 100))
      assert {:error, :message_too_large} = Reader.decode_frame(frame, max_bytes: 50)
    end

    test "accepts frame within max_bytes" do
      frame = build_frame(0x00, String.duplicate("x", 50))
      assert {:ok, _, _} = Reader.decode_frame(frame, max_bytes: 50)
    end

    test "accepts frame at exact max_bytes boundary" do
      frame = build_frame(0x00, String.duplicate("x", 100))
      assert {:ok, _, _} = Reader.decode_frame(frame, max_bytes: 100)
    end

    test "incomplete frame (header ok, payload short)" do
      assert {:error, :incomplete_frame} = Reader.decode_frame(<<0x00, 100::32, "short">>)
    end

    test "incomplete header (less than 5 bytes)" do
      assert {:error, :incomplete_header} = Reader.decode_frame(<<0x00, 1>>)
      assert {:error, :incomplete_header} = Reader.decode_frame(<<0x00>>)
    end

    test "empty buffer" do
      assert {:error, :empty_buffer} = Reader.decode_frame(<<>>)
    end
  end

  # --- read_all/2 ---

  describe "read_all/2" do
    test "reads multiple data frames" do
      data = build_frame(0x00, "a") <> build_frame(0x00, "b") <> build_frame(0x00, "c")
      assert {:ok, frames, nil} = Reader.read_all(data)
      assert length(frames) == 3
      assert Enum.map(frames, & &1.payload) == ["a", "b", "c"]
    end

    test "reads data frames followed by end-stream" do
      data = build_frame(0x00, "a") <> build_frame(0x00, "b") <> build_frame(0x02, "{}")
      assert {:ok, frames, end_stream} = Reader.read_all(data)
      assert length(frames) == 2
      assert end_stream.end_stream?
      assert end_stream.payload == "{}"
    end

    test "single end-stream frame" do
      data = build_frame(0x02, "{}")
      assert {:ok, [], end_stream} = Reader.read_all(data)
      assert end_stream.end_stream?
    end

    test "empty buffer returns empty" do
      assert {:ok, [], nil} = Reader.read_all(<<>>)
    end

    test "rejects extra bytes after end-stream" do
      data = build_frame(0x02, "{}") <> "garbage"
      assert {:error, :extra_bytes_after_end_stream} = Reader.read_all(data)
    end

    test "rejects data frame after end-stream" do
      data = build_frame(0x02, "{}") <> build_frame(0x00, "late")
      assert {:error, :extra_bytes_after_end_stream} = Reader.read_all(data)
    end

    test "max_bytes enforced per frame" do
      data = build_frame(0x00, "short") <> build_frame(0x00, String.duplicate("x", 100))
      assert {:error, :message_too_large} = Reader.read_all(data, max_bytes: 50)
    end

    test "reserved bits rejected in any frame" do
      data = build_frame(0x00, "ok") <> build_frame(0x04, "bad")
      assert {:error, :reserved_bits_set} = Reader.read_all(data)
    end
  end

  # --- read_single_message/2 ---

  describe "read_single_message/2" do
    test "reads a single data frame" do
      data = build_frame(0x00, "payload")
      assert {:ok, "payload", nil} = Reader.read_single_message(data)
    end

    test "reads data frame + end-stream" do
      data = build_frame(0x00, "payload") <> build_frame(0x02, "{}")
      assert {:ok, "payload", %{end_stream?: true}} = Reader.read_single_message(data)
    end

    test "rejects leading end-stream" do
      data = build_frame(0x02, "{}")
      assert {:error, :unexpected_end_stream} = Reader.read_single_message(data)
    end

    test "rejects compressed frame" do
      data = build_frame(0x01, "compressed")
      assert {:error, :compression_not_supported} = Reader.read_single_message(data)
    end

    test "rejects multiple data frames (cardinality violation)" do
      data = build_frame(0x00, "first") <> build_frame(0x00, "second")
      assert {:error, :multiple_messages_in_unary} = Reader.read_single_message(data)
    end

    test "rejects extra bytes after end-stream" do
      data = build_frame(0x00, "payload") <> build_frame(0x02, "{}") <> "extra"
      assert {:error, :extra_bytes_after_end_stream} = Reader.read_single_message(data)
    end

    test "max_bytes enforced on data frame" do
      data = build_frame(0x00, String.duplicate("x", 200))
      assert {:error, :message_too_large} = Reader.read_single_message(data, max_bytes: 100)
    end

    test "max_bytes enforced on end-stream frame" do
      data = build_frame(0x00, "ok") <> build_frame(0x02, String.duplicate("x", 200))
      assert {:error, :message_too_large} = Reader.read_single_message(data, max_bytes: 100)
    end

    test "empty buffer" do
      assert {:error, :empty_buffer} = Reader.read_single_message(<<>>)
    end
  end
end
