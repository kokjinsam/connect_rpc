defmodule ConnectRPC.TestProto.EchoService do
  @moduledoc false
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
  @moduledoc false
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
  @moduledoc false
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
  @moduledoc false
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
  @moduledoc false
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

defmodule ConnectRPC.TestProto.DirectSendService do
  @moduledoc false

  def __connect_rpc_service__ do
    %{
      name: "connectrpc.test.v1.DirectSendService",
      methods: [
        %{
          name: "DirectSend",
          request: ConnectRPC.TestProto.EchoRequest,
          response: ConnectRPC.TestProto.EchoResponse
        }
      ]
    }
  end
end

defmodule ConnectRPC.TestHandlers.EchoHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  def echo(%ConnectRPC.TestProto.EchoRequest{message: message}, _conn) do
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: message}}
  end
end

defmodule ConnectRPC.TestHandlers.FailHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "name is required")}
  end
end

defmodule ConnectRPC.TestHandlers.RaiseConnectErrorHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    raise ConnectRPC.Error, code: :not_found, message: "user not found"
  end
end

defmodule ConnectRPC.TestHandlers.CrashHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.CrashService

  def boom(_request, _conn) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.MismatchHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.MismatchService

  def mismatch(_request, _conn) do
    {:ok, %{foo: "bar"}}
  end
end

defmodule ConnectRPC.TestHandlers.NotifyHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  def echo(request, _conn) do
    send(self(), {:handler_invoked, request.message})
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: request.message}}
  end
end

defmodule ConnectRPC.TestHandlers.StreamingOnlyHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.StreamingService
end

defmodule ConnectRPC.TestHandlers.DirectSendHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.DirectSendService

  def direct_send(_request, conn) do
    Plug.Conn.send_resp(conn, 200, "sent directly")
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: "ignored"}}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataSuccessHandler do
  @moduledoc false

  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _conn) do
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

  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    metadata = [
      response_headers: [%{"name" => "x-error-meta", "value" => ["left", "right"]}],
      response_trailers: [%{"name" => "x-error-trailer", "value" => ["trailer-value"]}]
    ]

    {:error, ConnectRPC.Error.new(:invalid_argument, "metadata failure"), metadata}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataInvalidHandler do
  @moduledoc false

  use ConnectRPC.Handler, service: ConnectRPC.TestProto.EchoService

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(%EchoRequest{message: message}, _conn) do
    metadata = %{
      response_headers: [
        %{name: "x invalid", value: ["bad"]}
      ]
    }

    {:ok, %EchoResponse{message: message}, metadata}
  end
end

defmodule ConnectRPC.TestHandlers.BadDetailHandler do
  @moduledoc false
  use ConnectRPC.Handler, service: ConnectRPC.TestProto.FailService

  def fail(_request, _conn) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "bad request", [%{invalid: "detail"}])}
  end
end

defmodule ConnectRPC.TestCodecs.EchoText do
  @moduledoc false

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def id, do: :echo_text
  def media_type, do: "application/x-echo-text"

  def decode(payload, EchoRequest) when is_binary(payload) do
    {:ok, %EchoRequest{message: payload}}
  end

  def decode(_payload, _module), do: {:error, :unsupported_request_type}

  def encode(%EchoResponse{message: message}) when is_binary(message) do
    {:ok, message}
  end

  def encode(_other), do: {:error, :unsupported_response_type}
end
