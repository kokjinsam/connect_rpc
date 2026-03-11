defmodule ConnectRPC.RouterTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  defmodule AfterDecodePlug do
    @moduledoc false
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      if is_map(conn.assigns[:connect_rpc_request]) do
        put_resp_header(conn, "x-after-decode", "true")
      else
        raise "connect_rpc_request not assigned before inside-service pipeline"
      end
    end
  end

  defmodule PipelineHandler do
    @moduledoc false
    use ConnectRPC.Handler

    def echo(request, _context) do
      {:ok, %EchoResponse{message: request.message}}
    end
  end

  defmodule PipelineRouter do
    @moduledoc false
    use Phoenix.Router
    use ConnectRPC.Router

    pipeline :after_decode do
      plug(ConnectRPC.RouterTest.AfterDecodePlug)
    end

    service "/connectrpc.test.v1.PipelineService", ConnectRPC.RouterTest.PipelineHandler do
      pipe_through(:after_decode)

      rpc("/Echo", :echo,
        request: EchoRequest,
        response: EchoResponse
      )
    end
  end

  test "sets rpc metadata in conn.private" do
    conn =
      :post
      |> conn("/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn = ConnectRPC.TestRouter.call(conn, ConnectRPC.TestRouter.init([]))

    assert conn.private.connect_rpc_rpc.request == EchoRequest
    assert conn.private.connect_rpc_rpc.response == EchoResponse
    assert conn.private.connect_rpc_rpc.action == :echo
    assert conn.private.connect_rpc_rpc.service_name == "connectrpc.test.v1.EchoService"
  end

  test "pipe_through inside service runs after decode" do
    conn =
      :post
      |> conn("/connectrpc.test.v1.PipelineService/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn = PipelineRouter.call(conn, PipelineRouter.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "x-after-decode") == ["true"]
  end

  test "multiple services can coexist in one router" do
    conn1 =
      :post
      |> conn("/connectrpc.test.v1.EchoService/Echo", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn2 =
      :post
      |> conn("/connectrpc.test.v1.FailService/Fail", ~s({"message":"hello"}))
      |> put_req_header("content-type", "application/json")
      |> put_req_header("connect-protocol-version", "1")

    conn1 = ConnectRPC.TestRouter.call(conn1, ConnectRPC.TestRouter.init([]))
    conn2 = ConnectRPC.TestRouter.call(conn2, ConnectRPC.TestRouter.init([]))

    assert conn1.status == 200
    assert conn2.status == 400
  end

  test "raises compile error when handler function is missing" do
    code = """
    defmodule MissingHandlerForRouterTest do
      use ConnectRPC.Handler
    end

    defmodule MissingRouterForRouterTest do
      use Phoenix.Router
      use ConnectRPC.Router

      service "/test.v1.Svc", MissingHandlerForRouterTest do
        rpc "/Foo", :foo, request: ConnectRPC.TestProto.EchoRequest, response: ConnectRPC.TestProto.EchoResponse
      end
    end
    """

    assert_raise CompileError, ~r/undefined function .*\.foo\/2/, fn ->
      Code.compile_string(code)
    end
  end

  test "raises when proto module is missing" do
    code = """
    defmodule MissingProtoRouterForRouterTest do
      use Phoenix.Router
      use ConnectRPC.Router

      service "/test.v1.Svc", ConnectRPC.TestHandlers.EchoHandler do
        rpc "/Foo", :echo, request: MissingProtoModule, response: ConnectRPC.TestProto.EchoResponse
      end
    end
    """

    assert_raise CompileError, fn ->
      Code.compile_string(code)
    end
  end
end
