defmodule Connect.Envelope.WriterTest do
  use ExUnit.Case, async: true

  alias Connect.Envelope.Writer

  describe "data/1" do
    test "wraps payload with zero flags" do
      frame = Writer.data("hello")
      assert <<0x00, 5::32, "hello">> = frame
    end

    test "empty payload" do
      frame = Writer.data("")
      assert <<0x00, 0::32>> = frame
    end

    test "large payload length is correct" do
      payload = :binary.copy(<<0>>, 100_000)
      <<0x00, len::32, rest::binary>> = Writer.data(payload)
      assert len == 100_000
      assert byte_size(rest) == 100_000
    end

    test "binary payload preserved" do
      payload = <<1, 2, 3, 255, 0, 128>>
      <<0x00, 6::32, data::binary-size(6)>> = Writer.data(payload)
      assert data == payload
    end
  end

  describe "data_compressed/1" do
    test "sets compression flag (0x01)" do
      frame = Writer.data_compressed("compressed-data")
      <<flags::8, _len::32, _payload::binary>> = frame
      assert Bitwise.band(flags, 0x01) == 0x01
      assert Bitwise.band(flags, 0x02) == 0x00
    end

    test "payload preserved" do
      <<0x01, 15::32, payload::binary-size(15)>> = Writer.data_compressed("compressed-data")
      assert payload == "compressed-data"
    end
  end

  describe "end_stream/0..1" do
    test "sets end-stream flag (0x02)" do
      frame = Writer.end_stream(%{})
      <<flags::8, _len::32, _payload::binary>> = frame
      assert Bitwise.band(flags, 0x02) == 0x02
      assert Bitwise.band(flags, 0x01) == 0x00
    end

    test "encodes metadata as JSON" do
      frame = Writer.end_stream(%{"error" => %{"code" => "internal"}})
      <<0x02, len::32, payload::binary-size(len)>> = frame
      decoded = Jason.decode!(payload)
      assert decoded["error"]["code"] == "internal"
    end

    test "default metadata is empty object" do
      frame = Writer.end_stream()
      <<0x02, len::32, payload::binary-size(len)>> = frame
      assert Jason.decode!(payload) == %{}
    end
  end
end
