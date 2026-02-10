defmodule ConnectTest do
  use ExUnit.Case
  doctest Connect

  test "greets the world" do
    assert Connect.hello() == :world
  end
end
