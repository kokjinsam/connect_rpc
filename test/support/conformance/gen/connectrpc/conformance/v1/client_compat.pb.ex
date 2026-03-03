defmodule Connectrpc.Conformance.V1.ClientCompatRequest.Cancel do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientCompatRequest.Cancel",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Cancel",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "before_close_send",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Empty",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "beforeCloseSend",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "after_close_send_ms",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "afterCloseSendMs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "after_num_responses",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "afterNumResponses",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "cancel_timing",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :cancel_timing, 0

  field :before_close_send, 1, type: Google.Protobuf.Empty, json_name: "beforeCloseSend", oneof: 0
  field :after_close_send_ms, 2, type: :uint32, json_name: "afterCloseSendMs", oneof: 0
  field :after_num_responses, 3, type: :uint32, json_name: "afterNumResponses", oneof: 0
end

defmodule Connectrpc.Conformance.V1.ClientCompatRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientCompatRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientCompatRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "test_name",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "testName",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "http_version",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.HTTPVersion",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "httpVersion",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "protocol",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Protocol",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "protocol",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "codec",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Codec",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "codec",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "compression",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Compression",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "compression",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "host",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "host",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "port",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "port",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "server_tls_cert",
          extendee: nil,
          number: 8,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "serverTlsCert",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "client_tls_creds",
          extendee: nil,
          number: 9,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.TLSCreds",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "clientTlsCreds",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "message_receive_limit",
          extendee: nil,
          number: 10,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "messageReceiveLimit",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "service",
          extendee: nil,
          number: 11,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "service",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "method",
          extendee: nil,
          number: 12,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 1,
          json_name: "method",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "stream_type",
          extendee: nil,
          number: 13,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.StreamType",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "streamType",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "use_get_http_method",
          extendee: nil,
          number: 14,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "useGetHttpMethod",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_headers",
          extendee: nil,
          number: 15,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestHeaders",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_messages",
          extendee: nil,
          number: 16,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestMessages",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "timeout_ms",
          extendee: nil,
          number: 17,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 2,
          json_name: "timeoutMs",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_delay_ms",
          extendee: nil,
          number: 18,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestDelayMs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "cancel",
          extendee: nil,
          number: 19,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ClientCompatRequest.Cancel",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "cancel",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "raw_request",
          extendee: nil,
          number: 20,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.RawHTTPRequest",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "rawRequest",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [
        %Google.Protobuf.DescriptorProto{
          name: "Cancel",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "before_close_send",
              extendee: nil,
              number: 1,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".google.protobuf.Empty",
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "beforeCloseSend",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "after_close_send_ms",
              extendee: nil,
              number: 2,
              label: :LABEL_OPTIONAL,
              type: :TYPE_UINT32,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "afterCloseSendMs",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "after_num_responses",
              extendee: nil,
              number: 3,
              label: :LABEL_OPTIONAL,
              type: :TYPE_UINT32,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "afterNumResponses",
              proto3_optional: nil,
              __unknown_fields__: []
            }
          ],
          nested_type: [],
          enum_type: [],
          extension_range: [],
          extension: [],
          options: nil,
          oneof_decl: [
            %Google.Protobuf.OneofDescriptorProto{
              name: "cancel_timing",
              options: nil,
              __unknown_fields__: []
            }
          ],
          reserved_range: [],
          reserved_name: [],
          __unknown_fields__: []
        }
      ],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "_service",
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.OneofDescriptorProto{
          name: "_method",
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.OneofDescriptorProto{
          name: "_timeout_ms",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :test_name, 1, type: :string, json_name: "testName"

  field :http_version, 2,
    type: Connectrpc.Conformance.V1.HTTPVersion,
    json_name: "httpVersion",
    enum: true

  field :protocol, 3, type: Connectrpc.Conformance.V1.Protocol, enum: true
  field :codec, 4, type: Connectrpc.Conformance.V1.Codec, enum: true
  field :compression, 5, type: Connectrpc.Conformance.V1.Compression, enum: true
  field :host, 6, type: :string
  field :port, 7, type: :uint32
  field :server_tls_cert, 8, type: :bytes, json_name: "serverTlsCert"

  field :client_tls_creds, 9,
    type: Connectrpc.Conformance.V1.TLSCreds,
    json_name: "clientTlsCreds"

  field :message_receive_limit, 10, type: :uint32, json_name: "messageReceiveLimit"
  field :service, 11, proto3_optional: true, type: :string
  field :method, 12, proto3_optional: true, type: :string

  field :stream_type, 13,
    type: Connectrpc.Conformance.V1.StreamType,
    json_name: "streamType",
    enum: true

  field :use_get_http_method, 14, type: :bool, json_name: "useGetHttpMethod"

  field :request_headers, 15,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "requestHeaders"

  field :request_messages, 16,
    repeated: true,
    type: Google.Protobuf.Any,
    json_name: "requestMessages"

  field :timeout_ms, 17, proto3_optional: true, type: :uint32, json_name: "timeoutMs"
  field :request_delay_ms, 18, type: :uint32, json_name: "requestDelayMs"
  field :cancel, 19, type: Connectrpc.Conformance.V1.ClientCompatRequest.Cancel
  field :raw_request, 20, type: Connectrpc.Conformance.V1.RawHTTPRequest, json_name: "rawRequest"
end

defmodule Connectrpc.Conformance.V1.ClientCompatResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientCompatResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientCompatResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "test_name",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "testName",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "response",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ClientResponseResult",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "response",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "error",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ClientErrorResult",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "error",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "result",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :result, 0

  field :test_name, 1, type: :string, json_name: "testName"
  field :response, 2, type: Connectrpc.Conformance.V1.ClientResponseResult, oneof: 0
  field :error, 3, type: Connectrpc.Conformance.V1.ClientErrorResult, oneof: 0
end

defmodule Connectrpc.Conformance.V1.ClientResponseResult do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientResponseResult",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientResponseResult",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_headers",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseHeaders",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "payloads",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payloads",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "error",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Error",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "error",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_trailers",
          extendee: nil,
          number: 4,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseTrailers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "num_unsent_requests",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "numUnsentRequests",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "http_status_code",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "httpStatusCode",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "feedback",
          extendee: nil,
          number: 7,
          label: :LABEL_REPEATED,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "feedback",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "_http_status_code",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :response_headers, 1,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseHeaders"

  field :payloads, 2, repeated: true, type: Connectrpc.Conformance.V1.ConformancePayload
  field :error, 3, type: Connectrpc.Conformance.V1.Error

  field :response_trailers, 4,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseTrailers"

  field :num_unsent_requests, 5, type: :int32, json_name: "numUnsentRequests"
  field :http_status_code, 6, proto3_optional: true, type: :int32, json_name: "httpStatusCode"
  field :feedback, 7, repeated: true, type: :string
end

defmodule Connectrpc.Conformance.V1.ClientErrorResult do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientErrorResult",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientErrorResult",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "message",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "message",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :message, 1, type: :string
end

defmodule Connectrpc.Conformance.V1.WireDetails do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.WireDetails",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "WireDetails",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "actual_status_code",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "actualStatusCode",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "connect_error_raw",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Struct",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "connectErrorRaw",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "actual_http_trailers",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "actualHttpTrailers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "actual_grpcweb_trailers",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "actualGrpcwebTrailers",
          proto3_optional: true,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{
          name: "_actual_grpcweb_trailers",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :actual_status_code, 1, type: :int32, json_name: "actualStatusCode"
  field :connect_error_raw, 2, type: Google.Protobuf.Struct, json_name: "connectErrorRaw"

  field :actual_http_trailers, 3,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "actualHttpTrailers"

  field :actual_grpcweb_trailers, 4,
    proto3_optional: true,
    type: :string,
    json_name: "actualGrpcwebTrailers"
end
