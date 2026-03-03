defmodule Connectrpc.Conformance.V1.ServerCompatRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ServerCompatRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerCompatRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "protocol",
          extendee: nil,
          number: 1,
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
          name: "use_tls",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "useTls",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "client_tls_cert",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "clientTlsCert",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "message_receive_limit",
          extendee: nil,
          number: 6,
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
          name: "server_creds",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.TLSCreds",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "serverCreds",
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

  field :protocol, 1, type: Connectrpc.Conformance.V1.Protocol, enum: true

  field :http_version, 2,
    type: Connectrpc.Conformance.V1.HTTPVersion,
    json_name: "httpVersion",
    enum: true

  field :use_tls, 4, type: :bool, json_name: "useTls"
  field :client_tls_cert, 5, type: :bytes, json_name: "clientTlsCert"
  field :message_receive_limit, 6, type: :uint32, json_name: "messageReceiveLimit"
  field :server_creds, 7, type: Connectrpc.Conformance.V1.TLSCreds, json_name: "serverCreds"
end

defmodule Connectrpc.Conformance.V1.ServerCompatResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ServerCompatResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerCompatResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "host",
          extendee: nil,
          number: 1,
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
          number: 2,
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
          name: "pem_cert",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "pemCert",
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

  field :host, 1, type: :string
  field :port, 2, type: :uint32
  field :pem_cert, 3, type: :bytes, json_name: "pemCert"
end
