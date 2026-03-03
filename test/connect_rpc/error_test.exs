defmodule ConnectRPC.ErrorTest do
  use ExUnit.Case, async: true

  alias ConnectRPC.Error

  test "new/3 builds an error with valid code" do
    error = Error.new(:invalid_argument, "invalid input")

    assert error.code == :invalid_argument
    assert error.message == "invalid input"
    assert error.details == []
  end

  test "new/3 normalizes unknown code to :unknown" do
    error = Error.new(:nope, "invalid")

    assert error.code == :unknown
  end

  test "new/3 wraps non-list details" do
    detail = %ConnectRPC.TestProto.Detail{reason: "bad"}
    error = Error.new(:invalid_argument, "invalid", detail)

    assert error.details == [detail]
  end

  test "valid_code?/1 returns true only for known codes" do
    assert Error.valid_code?(:internal)
    refute Error.valid_code?(:not_a_code)
    refute Error.valid_code?("internal")
  end
end
