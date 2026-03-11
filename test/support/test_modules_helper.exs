defmodule ConnectRPC.TestHandlers.EchoHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def echo(%ConnectRPC.TestProto.EchoRequest{message: message}, _context) do
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: message}}
  end
end

defmodule ConnectRPC.TestHandlers.FailHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_request, _context) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "name is required")}
  end
end

defmodule ConnectRPC.TestHandlers.RaiseConnectErrorHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_request, _context) do
    raise ConnectRPC.Error, code: :not_found, message: "user not found"
  end
end

defmodule ConnectRPC.TestHandlers.CrashHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def boom(_request, _context) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.DebugCrashHandler do
  @moduledoc false
  use ConnectRPC.Handler, debug_exceptions: true

  def boom(_request, _context) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.MismatchHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def mismatch(_request, _context) do
    {:ok, %{foo: "bar"}}
  end
end

defmodule ConnectRPC.TestHandlers.NotifyHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def echo(request, _context) do
    send(self(), {:handler_invoked, request.message})
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: request.message}}
  end
end

defmodule ConnectRPC.TestHandlers.ContextHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, %ConnectRPC.Context{} = context) do
    send(self(), {:handler_context, context})
    {:ok, %EchoResponse{message: message}}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataSuccessHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "x-meta-map", value: ["one", "two"]},
        {"x-meta-tuple", "tuple-value"}
      ],
      response_trailers: [
        %{name: "x-meta-trailer", value: ["trailer-value"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataErrorHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_request, _context) do
    metadata = [
      response_headers: [%{"name" => "x-error-meta", "value" => ["left", "right"]}],
      response_trailers: [%{"name" => "x-error-trailer", "value" => ["trailer-value"]}]
    ]

    {:error, ConnectRPC.Error.new(:invalid_argument, "metadata failure"), metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataInvalidHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "x invalid", value: ["bad"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataReservedHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "connect-custom", value: ["reserved"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataAsciiInvalidHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "x-meta-ascii", value: ["héllo"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataBinaryHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "x-meta-bytes-bin", value: ["AQI="]}
      ],
      response_trailers: [
        %{name: "x-meta-trailer-bytes-bin", value: ["AQI="]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataBinaryInvalidHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _context) do
    metadata = %{
      response_headers: [
        %{name: "x-meta-bytes-bin", value: ["###not-base64###"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.BadDetailHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_request, _context) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "bad request", [%{invalid: "detail"}])}
  end
end

defmodule ConnectRPC.TestPlugs.ContextAssign do
  @moduledoc false
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    ConnectRPC.Context.put(conn, :upstream_value, "from-upstream")
  end
end

defmodule ConnectRPC.TestRouter do
  @moduledoc false
  use Phoenix.Router
  use ConnectRPC.Router

  alias ConnectRPC.TestHandlers.ContextHandler
  alias ConnectRPC.TestHandlers.EchoHandler
  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  pipeline :context_assign do
    plug(ConnectRPC.TestPlugs.ContextAssign)
  end

  service "/connectrpc.test.v1.EchoService", EchoHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.FailService", ConnectRPC.TestHandlers.FailHandler do
    rpc("/Fail", :fail,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.RaiseService", ConnectRPC.TestHandlers.RaiseConnectErrorHandler do
    rpc("/Fail", :fail,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.CrashService", ConnectRPC.TestHandlers.CrashHandler do
    rpc("/Boom", :boom,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.DebugCrashService", ConnectRPC.TestHandlers.DebugCrashHandler do
    rpc("/Boom", :boom,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MismatchService", ConnectRPC.TestHandlers.MismatchHandler do
    rpc("/Mismatch", :mismatch,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.NotifyService", ConnectRPC.TestHandlers.NotifyHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.ContextService", ContextHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.ContextAssignedService", ContextHandler do
    pipe_through(:context_assign)

    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataSuccessService", ConnectRPC.TestHandlers.MetadataSuccessHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataErrorService", ConnectRPC.TestHandlers.MetadataErrorHandler do
    rpc("/Fail", :fail,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataInvalidService", ConnectRPC.TestHandlers.MetadataInvalidHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataReservedService", ConnectRPC.TestHandlers.MetadataReservedHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataAsciiInvalidService", ConnectRPC.TestHandlers.MetadataAsciiInvalidHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataBinaryService", ConnectRPC.TestHandlers.MetadataBinaryHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.MetadataBinaryInvalidService", ConnectRPC.TestHandlers.MetadataBinaryInvalidHandler do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.BadDetailService", ConnectRPC.TestHandlers.BadDetailHandler do
    rpc("/Fail", :fail,
      request: EchoRequest,
      response: EchoResponse
    )
  end
end

defmodule ConnectRPC.TestEndpoint do
  @moduledoc false

  use Plug.Builder

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, ConnectRPC.Parser, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(ConnectRPC.TestRouter)
end
