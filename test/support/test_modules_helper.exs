defmodule ConnectRPC.TestHandlers.EchoHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def echo(_conn, %ConnectRPC.TestProto.EchoRequest{message: message}) do
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: message}}
  end
end

defmodule ConnectRPC.TestHandlers.FailHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_conn, _request) do
    {:error, ConnectRPC.Error.new(:invalid_argument, "name is required")}
  end
end

defmodule ConnectRPC.TestHandlers.RaiseConnectErrorHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def fail(_conn, _request) do
    raise ConnectRPC.Error, code: :not_found, message: "user not found"
  end
end

defmodule ConnectRPC.TestHandlers.CrashHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def boom(_conn, _request) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.DebugCrashHandler do
  @moduledoc false
  use ConnectRPC.Handler, debug_exceptions: true

  def boom(_conn, _request) do
    raise "boom"
  end
end

defmodule ConnectRPC.TestHandlers.MismatchHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def mismatch(_conn, _request) do
    {:ok, %{foo: "bar"}}
  end
end

defmodule ConnectRPC.TestHandlers.NotifyHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def echo(_conn, request) do
    send(self(), {:handler_invoked, request.message})
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: request.message}}
  end
end

defmodule ConnectRPC.TestHandlers.DirectSendHandler do
  @moduledoc false
  use ConnectRPC.Handler

  def direct_send(conn, _request) do
    Plug.Conn.send_resp(conn, 200, "sent directly")
    {:ok, %ConnectRPC.TestProto.EchoResponse{message: "ignored"}}
  end
end

defmodule ConnectRPC.TestHandlers.MetadataSuccessHandler do
  @moduledoc false
  use ConnectRPC.Handler

  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

  def echo(_conn, %EchoRequest{message: message}) do
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

  def fail(_conn, _request) do
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

  def echo(_conn, %EchoRequest{message: message}) do
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
  use ConnectRPC.Handler

  def fail(_conn, _request) do
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

defmodule ConnectRPC.TestRouter do
  @moduledoc false
  use Phoenix.Router
  use ConnectRPC.Router

  alias ConnectRPC.TestHandlers.EchoHandler
  alias ConnectRPC.TestProto.EchoRequest
  alias ConnectRPC.TestProto.EchoResponse

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

  service "/connectrpc.test.v1.DirectSendService", ConnectRPC.TestHandlers.DirectSendHandler do
    rpc("/DirectSend", :direct_send,
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

  service "/connectrpc.test.v1.BadDetailService", ConnectRPC.TestHandlers.BadDetailHandler do
    rpc("/Fail", :fail,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.CustomCodecService", EchoHandler, codecs: [ConnectRPC.TestCodecs.EchoText] do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end

  service "/connectrpc.test.v1.JsonOnlyService", EchoHandler, codecs: [ConnectRPC.Codec.JSON] do
    rpc("/Echo", :echo,
      request: EchoRequest,
      response: EchoResponse
    )
  end
end
