defmodule Connect.ErrorTest do
  use ExUnit.Case, async: true

  alias Connect.Error

  # --- new/1..3 ---

  describe "new/1..3" do
    test "creates error with code only" do
      error = Error.new("internal")
      assert error.code == "internal"
      assert error.message == nil
      assert error.details == []
      assert error.metadata == %{}
    end

    test "creates error with code and message" do
      error = Error.new("not_found", "User 123 not found")
      assert error.code == "not_found"
      assert error.message == "User 123 not found"
    end

    test "creates error with details" do
      detail = %{type: "type.googleapis.com/foo.Bar", value: <<1, 2, 3>>}
      error = Error.new("internal", "oops", details: [detail])
      assert length(error.details) == 1
      assert hd(error.details) == detail
    end

    test "creates error with metadata" do
      error = Error.new("internal", "oops", metadata: %{"x-req-id" => "abc"})
      assert error.metadata == %{"x-req-id" => "abc"}
    end

    test "raises on invalid code" do
      assert_raise ArgumentError, ~r/invalid Connect error code/, fn ->
        Error.new("bogus", "nope")
      end
    end

    test "raises on empty string code" do
      assert_raise ArgumentError, fn -> Error.new("", "msg") end
    end

    test "raises on uppercase code" do
      assert_raise ArgumentError, fn -> Error.new("INTERNAL", "msg") end
    end
  end

  # --- valid_code?/1 ---

  describe "valid_code?/1" do
    test "all 16 codes are valid" do
      for code <- Error.valid_codes() do
        assert Error.valid_code?(code), "expected #{code} to be valid"
      end
    end

    test "exactly 16 valid codes" do
      assert length(Error.valid_codes()) == 16
    end

    test "bogus codes are invalid" do
      refute Error.valid_code?("bogus")
      refute Error.valid_code?("")
      refute Error.valid_code?("INTERNAL")
    end
  end

  # --- code_to_http_status/1 (FIXED mappings) ---

  describe "code_to_http_status/1" do
    @expected_mappings %{
      "canceled" => 499,
      "unknown" => 500,
      "invalid_argument" => 400,
      "deadline_exceeded" => 504,
      "not_found" => 404,
      "already_exists" => 409,
      "permission_denied" => 403,
      "resource_exhausted" => 429,
      "failed_precondition" => 400,
      "aborted" => 409,
      "out_of_range" => 400,
      "unimplemented" => 501,
      "internal" => 500,
      "unavailable" => 503,
      "data_loss" => 500,
      "unauthenticated" => 401
    }

    test "all codes map to expected statuses" do
      for {code, status} <- @expected_mappings do
        assert Error.code_to_http_status(code) == status,
               "#{code} should map to #{status}, got #{Error.code_to_http_status(code)}"
      end
    end

    # Verify the 4 previously wrong codes explicitly
    test "canceled -> 499 (was 408)" do
      assert Error.code_to_http_status("canceled") == 499
    end

    test "deadline_exceeded -> 504 (was 408)" do
      assert Error.code_to_http_status("deadline_exceeded") == 504
    end

    test "failed_precondition -> 400 (was 412)" do
      assert Error.code_to_http_status("failed_precondition") == 400
    end

    test "unimplemented -> 501 (was 404)" do
      assert Error.code_to_http_status("unimplemented") == 501
    end

    test "unknown code defaults to 500" do
      assert Error.code_to_http_status("nonexistent") == 500
    end
  end

  # --- to_json/1 and to_wire_map/1 ---

  describe "to_wire_map/1" do
    test "code only — omits message and details" do
      error = Error.new("internal")
      map = Error.to_wire_map(error)
      assert map == %{"code" => "internal"}
      refute Map.has_key?(map, "message")
      refute Map.has_key?(map, "details")
    end

    test "code and message" do
      error = Error.new("not_found", "gone")
      assert Error.to_wire_map(error) == %{"code" => "not_found", "message" => "gone"}
    end

    test "includes base64-encoded details" do
      detail = %{type: "type.googleapis.com/foo.Bar", value: <<1, 2, 3>>}
      error = Error.new("internal", "oops", details: [detail])
      map = Error.to_wire_map(error)

      assert [%{"type" => "type.googleapis.com/foo.Bar", "value" => value_b64}] = map["details"]
      assert {:ok, <<1, 2, 3>>} = Base.decode64(value_b64)
    end

    test "includes debug in details when present" do
      detail = %{type: "type.googleapis.com/foo.Bar", value: <<>>, debug: %{"key" => "val"}}
      error = Error.new("internal", nil, details: [detail])
      map = Error.to_wire_map(error)

      assert [%{"debug" => %{"key" => "val"}}] = map["details"]
    end
  end

  describe "to_json/1" do
    test "produces valid JSON" do
      error = Error.new("not_found", "gone")
      json = Error.to_json(error)
      assert {:ok, _} = Jason.decode(json)
    end

    test "round-trips through JSON" do
      error = Error.new("not_found", "gone")
      decoded = Jason.decode!(Error.to_json(error))
      assert decoded == %{"code" => "not_found", "message" => "gone"}
    end
  end

  # --- from_wire_map/1 ---

  describe "from_wire_map/1" do
    test "parses valid error" do
      map = %{"code" => "not_found", "message" => "gone"}
      assert {:ok, error} = Error.from_wire_map(map)
      assert error.code == "not_found"
      assert error.message == "gone"
    end

    test "parses error with details" do
      map = %{
        "code" => "internal",
        "details" => [
          %{"type" => "type.googleapis.com/foo.Bar", "value" => Base.encode64(<<1, 2, 3>>)}
        ]
      }

      assert {:ok, error} = Error.from_wire_map(map)
      assert [%{type: "type.googleapis.com/foo.Bar", value: <<1, 2, 3>>}] = error.details
    end

    test "rejects invalid code" do
      assert {:error, :invalid_error_code} = Error.from_wire_map(%{"code" => "bogus"})
    end

    test "rejects missing code" do
      assert {:error, :invalid_error_format} = Error.from_wire_map(%{"message" => "hi"})
    end

    test "rejects non-map input" do
      assert {:error, :invalid_error_format} = Error.from_wire_map("not a map")
    end
  end

  # --- to_end_stream/1 ---

  describe "to_end_stream/1" do
    test "wraps error in end-stream format" do
      error = Error.new("internal", "stream failed")
      result = Error.to_end_stream(error)
      assert %{"error" => %{"code" => "internal", "message" => "stream failed"}} = result
    end

    test "includes metadata when present" do
      error = Error.new("internal", "fail", metadata: %{"x-id" => "abc"})
      result = Error.to_end_stream(error)
      assert Map.has_key?(result, "metadata")
      assert result["metadata"]["x-id"] == ["abc"]
    end

    test "omits metadata when empty" do
      error = Error.new("internal", "fail")
      result = Error.to_end_stream(error)
      refute Map.has_key?(result, "metadata")
    end
  end

  # --- send_unary/2 ---

  describe "send_unary/2" do
    test "uses correct HTTP status and JSON content-type" do
      conn = Plug.Test.conn(:post, "/")
      result = Error.send_unary(conn, Error.new("not_found", "gone"))
      assert result.status == 404

      assert Plug.Conn.get_resp_header(result, "content-type")
             |> List.first()
             |> String.contains?("application/json")

      body = Jason.decode!(result.resp_body)
      assert body["code"] == "not_found"
      assert body["message"] == "gone"
    end

    test "canceled maps to 499" do
      conn = Plug.Test.conn(:post, "/")
      result = Error.send_unary(conn, Error.new("canceled", "cancelled"))
      assert result.status == 499
    end

    test "unimplemented maps to 501" do
      conn = Plug.Test.conn(:post, "/")
      result = Error.send_unary(conn, Error.new("unimplemented", "not impl"))
      assert result.status == 501
    end
  end
end
