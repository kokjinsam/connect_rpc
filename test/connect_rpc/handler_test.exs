defmodule ConnectRPC.HandlerTest do
  use ExUnit.Case, async: true

  test "exposes compiled service metadata through __connect_rpc__/1" do
    assert ConnectRPC.TestHandlers.EchoHandler.__connect_rpc__(:service_name) ==
             "connectrpc.test.v1.EchoService"

    methods = ConnectRPC.TestHandlers.EchoHandler.__connect_rpc__(:methods)
    method = methods["Echo"]

    assert method.function == :echo
    assert method.request == ConnectRPC.TestProto.EchoRequest
    assert method.response == ConnectRPC.TestProto.EchoResponse
  end

  test "raises compile error when unary handler function is missing" do
    module_name = Module.concat(__MODULE__, "Missing#{System.unique_integer([:positive])}")

    code = """
    defmodule #{inspect(module_name)} do
      use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService
    end
    """

    assert_raise CompileError, ~r/missing handler function echo\/2/, fn ->
      Code.compile_string(code)
    end
  end

  test "streaming-only service does not require unary callback" do
    module_name = Module.concat(__MODULE__, "Streaming#{System.unique_integer([:positive])}")

    code = """
    defmodule #{inspect(module_name)} do
      use ConnectRPC.Handler, service: ConnectRPC.TestProto.StreamingService
    end
    """

    assert [{^module_name, _bytecode}] = Code.compile_string(code)
    assert %{} = module_name.__connect_rpc__(:methods)
  end
end
