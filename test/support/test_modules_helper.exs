defmodule ConnectRPC.TestProto.EchoRequest do
  use Protobuf, syntax: :proto3

  field(:message, 1, type: :string)
end

defmodule ConnectRPC.TestProto.EchoResponse do
  use Protobuf, syntax: :proto3

  field(:message, 1, type: :string)
end

defmodule ConnectRPC.TestProto.Detail do
  use Protobuf, syntax: :proto3

  field(:reason, 1, type: :string)
end

defmodule ConnectRPC.TestProto.EchoService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.EchoService",
      methods: [
        %{
          name: "Echo",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestProto.FailService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.FailService",
      methods: [
        %{
          name: "Fail",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestProto.CrashService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.CrashService",
      methods: [
        %{
          name: "Boom",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestProto.MismatchService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.MismatchService",
      methods: [
        %{
          name: "Mismatch",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestProto.StreamingService do
  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.StreamingService",
      methods: [
        %{
          name: "ServerStreamEcho",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse,
          client_streaming?: false,
          server_streaming?: true
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestHandlers.EchoHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  def echo(%ConnectRPC.TestProto.EchoRequest{message: message}, _conn) do
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: message}}
  end
end

defmodule ConnectRPC.TestHandlers.FailHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "name is required")}
  end
end

defmodule ConnectRPC.TestHandlers.RaiseConnectErrorHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    raise ConnectRPC.Error, code: :not_found, message: "user not found"
  end
end

defmodule ConnectRPC.TestHandlers.CrashHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.CrashService

  def boom(_request, _conn) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.MismatchHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.MismatchService

  def mismatch(_request, _conn) do
    {:ok, %{foo: "bar"}}
  end
end

defmodule ConnectRPC.TestHandlers.NotifyHandler do
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  def echo(request, _conn) do
    send(self(), {:handler_invoked, request.message})
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: request.message}}
  end
end
