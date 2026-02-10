defmodule Connect.Protocol.HeadersTest do
  use ExUnit.Case, async: true

  alias Connect.Protocol.Headers

  # --- reserved?/1 ---

  describe "reserved?/1" do
    test "standard HTTP headers are reserved" do
      for name <- ~w(content-type content-length content-encoding host user-agent trailer date) do
        assert Headers.reserved?(name), "expected #{name} to be reserved"
      end
    end

    test "Connect protocol headers are reserved" do
      for name <-
            ~w(connect-protocol-version connect-timeout-ms connect-content-encoding connect-accept-encoding) do
        assert Headers.reserved?(name), "expected #{name} to be reserved"
      end
    end

    test "any connect- prefixed header is reserved" do
      assert Headers.reserved?("connect-foo-bar")
      assert Headers.reserved?("connect-custom")
    end

    test "case-insensitive matching" do
      assert Headers.reserved?("Content-Type")
      assert Headers.reserved?("CONNECT-PROTOCOL-VERSION")
      assert Headers.reserved?("Connect-Timeout-Ms")
    end

    test "application headers are not reserved" do
      refute Headers.reserved?("authorization")
      refute Headers.reserved?("x-request-id")
      refute Headers.reserved?("x-custom-header")
      refute Headers.reserved?("grpc-status")
    end
  end

  # --- filter_reserved/1 ---

  describe "filter_reserved/1" do
    test "removes reserved, keeps application headers" do
      headers = [
        {"content-type", "application/json"},
        {"x-request-id", "abc123"},
        {"connect-protocol-version", "1"},
        {"authorization", "Bearer token"},
        {"connect-timeout-ms", "5000"}
      ]

      result = Headers.filter_reserved(headers)

      assert result == [
               {"x-request-id", "abc123"},
               {"authorization", "Bearer token"}
             ]
    end

    test "empty list returns empty" do
      assert [] = Headers.filter_reserved([])
    end
  end

  # --- binary header encode/decode ---

  describe "encode_binary_header/1 and decode_binary_header/1" do
    test "round-trips binary data" do
      original = <<1, 2, 3, 255, 0, 128>>
      encoded = Headers.encode_binary_header(original)
      assert {:ok, ^original} = Headers.decode_binary_header(encoded)
    end

    test "handles empty binary" do
      encoded = Headers.encode_binary_header("")
      assert {:ok, ""} = Headers.decode_binary_header(encoded)
    end

    test "produces unpadded output" do
      # 1 byte encodes to 2 base64 chars (would need 2 pad chars)
      encoded = Headers.encode_binary_header(<<42>>)
      refute String.contains?(encoded, "=")
      assert {:ok, <<42>>} = Headers.decode_binary_header(encoded)
    end

    test "decodes padded input" do
      # Base64 with padding
      padded = Base.encode64(<<1, 2, 3>>)
      assert {:ok, <<1, 2, 3>>} = Headers.decode_binary_header(padded)
    end

    test "rejects invalid base64" do
      assert {:error, :invalid_base64} = Headers.decode_binary_header("!!invalid!!")
    end
  end

  # --- binary_header?/1 ---

  describe "binary_header?/1" do
    test "header ending in -bin is binary" do
      assert Headers.binary_header?("grpc-status-details-bin")
      assert Headers.binary_header?("custom-bin")
    end

    test "case-insensitive" do
      assert Headers.binary_header?("Custom-Bin")
      assert Headers.binary_header?("CUSTOM-BIN")
    end

    test "regular header is not binary" do
      refute Headers.binary_header?("x-request-id")
      refute Headers.binary_header?("authorization")
      refute Headers.binary_header?("binary")
    end
  end
end
