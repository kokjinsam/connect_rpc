defmodule Connect.EnvelopeTest do
  use ExUnit.Case, async: true

  alias Connect.Envelope

  describe "facade backward compatibility" do
    test "wrap_data delegates to Writer" do
      assert <<0x00, 5::32, "hello">> = Envelope.wrap_data("hello")
    end

    test "wrap_end delegates to Writer" do
      frame = Envelope.wrap_end(%{})
      <<flags::8, _::binary>> = frame
      assert Bitwise.band(flags, 0x02) == 0x02
    end

    test "wrap_end with no args uses empty metadata" do
      frame = Envelope.wrap_end()
      <<0x02, len::32, payload::binary-size(len)>> = frame
      assert Jason.decode!(payload) == %{}
    end

    test "decode_frame delegates to Reader" do
      frame = <<0x00, 5::32, "hello">>

      assert {:ok, %{payload: "hello", compressed?: false, end_stream?: false}, <<>>} =
               Envelope.decode_frame(frame)
    end

    test "decode_frame with opts delegates to Reader" do
      frame = <<0x00, 100::32, String.duplicate("x", 100)::binary>>
      assert {:error, :message_too_large} = Envelope.decode_frame(frame, max_bytes: 50)
    end
  end
end
