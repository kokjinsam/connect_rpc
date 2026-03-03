defmodule Connectrpc.Conformance.V1.TestSuite.TestMode do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.TestSuite.TestMode",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "TestMode",
      value: [
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "TEST_MODE_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "TEST_MODE_CLIENT",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "TEST_MODE_SERVER",
          number: 2,
          options: nil,
          __unknown_fields__: []
        }
      ],
      options: nil,
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :TEST_MODE_UNSPECIFIED, 0
  field :TEST_MODE_CLIENT, 1
  field :TEST_MODE_SERVER, 2
end

defmodule Connectrpc.Conformance.V1.TestSuite.ConnectVersionMode do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.TestSuite.ConnectVersionMode",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "ConnectVersionMode",
      value: [
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "CONNECT_VERSION_MODE_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "CONNECT_VERSION_MODE_REQUIRE",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumValueDescriptorProto{
          name: "CONNECT_VERSION_MODE_IGNORE",
          number: 2,
          options: nil,
          __unknown_fields__: []
        }
      ],
      options: nil,
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :CONNECT_VERSION_MODE_UNSPECIFIED, 0
  field :CONNECT_VERSION_MODE_REQUIRE, 1
  field :CONNECT_VERSION_MODE_IGNORE, 2
end

defmodule Connectrpc.Conformance.V1.TestSuite do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.TestSuite",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "TestSuite",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "name",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "name",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "mode",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.TestSuite.TestMode",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "mode",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "test_cases",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.TestCase",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "testCases",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relevant_protocols",
          extendee: nil,
          number: 4,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Protocol",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "relevantProtocols",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relevant_http_versions",
          extendee: nil,
          number: 5,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.HTTPVersion",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "relevantHttpVersions",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relevant_codecs",
          extendee: nil,
          number: 6,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Codec",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "relevantCodecs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relevant_compressions",
          extendee: nil,
          number: 7,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Compression",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "relevantCompressions",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "connect_version_mode",
          extendee: nil,
          number: 8,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.TestSuite.ConnectVersionMode",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "connectVersionMode",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relies_on_tls",
          extendee: nil,
          number: 9,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "reliesOnTls",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relies_on_tls_client_certs",
          extendee: nil,
          number: 10,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "reliesOnTlsClientCerts",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relies_on_connect_get",
          extendee: nil,
          number: 11,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "reliesOnConnectGet",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "relies_on_message_receive_limit",
          extendee: nil,
          number: 12,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "reliesOnMessageReceiveLimit",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [],
      enum_type: [
        %Google.Protobuf.EnumDescriptorProto{
          name: "TestMode",
          value: [
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "TEST_MODE_UNSPECIFIED",
              number: 0,
              options: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "TEST_MODE_CLIENT",
              number: 1,
              options: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "TEST_MODE_SERVER",
              number: 2,
              options: nil,
              __unknown_fields__: []
            }
          ],
          options: nil,
          reserved_range: [],
          reserved_name: [],
          __unknown_fields__: []
        },
        %Google.Protobuf.EnumDescriptorProto{
          name: "ConnectVersionMode",
          value: [
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "CONNECT_VERSION_MODE_UNSPECIFIED",
              number: 0,
              options: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "CONNECT_VERSION_MODE_REQUIRE",
              number: 1,
              options: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.EnumValueDescriptorProto{
              name: "CONNECT_VERSION_MODE_IGNORE",
              number: 2,
              options: nil,
              __unknown_fields__: []
            }
          ],
          options: nil,
          reserved_range: [],
          reserved_name: [],
          __unknown_fields__: []
        }
      ],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :name, 1, type: :string
  field :mode, 2, type: Connectrpc.Conformance.V1.TestSuite.TestMode, enum: true

  field :test_cases, 3,
    repeated: true,
    type: Connectrpc.Conformance.V1.TestCase,
    json_name: "testCases"

  field :relevant_protocols, 4,
    repeated: true,
    type: Connectrpc.Conformance.V1.Protocol,
    json_name: "relevantProtocols",
    enum: true

  field :relevant_http_versions, 5,
    repeated: true,
    type: Connectrpc.Conformance.V1.HTTPVersion,
    json_name: "relevantHttpVersions",
    enum: true

  field :relevant_codecs, 6,
    repeated: true,
    type: Connectrpc.Conformance.V1.Codec,
    json_name: "relevantCodecs",
    enum: true

  field :relevant_compressions, 7,
    repeated: true,
    type: Connectrpc.Conformance.V1.Compression,
    json_name: "relevantCompressions",
    enum: true

  field :connect_version_mode, 8,
    type: Connectrpc.Conformance.V1.TestSuite.ConnectVersionMode,
    json_name: "connectVersionMode",
    enum: true

  field :relies_on_tls, 9, type: :bool, json_name: "reliesOnTls"
  field :relies_on_tls_client_certs, 10, type: :bool, json_name: "reliesOnTlsClientCerts"
  field :relies_on_connect_get, 11, type: :bool, json_name: "reliesOnConnectGet"

  field :relies_on_message_receive_limit, 12,
    type: :bool,
    json_name: "reliesOnMessageReceiveLimit"
end

defmodule Connectrpc.Conformance.V1.TestCase.ExpandedSize do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.TestCase.ExpandedSize",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ExpandedSize",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "size_relative_to_limit",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "sizeRelativeToLimit",
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
          name: "_size_relative_to_limit",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :size_relative_to_limit, 1,
    proto3_optional: true,
    type: :int32,
    json_name: "sizeRelativeToLimit"
end

defmodule Connectrpc.Conformance.V1.TestCase do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.TestCase",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "TestCase",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "request",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ClientCompatRequest",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "request",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "expand_requests",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.TestCase.ExpandedSize",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "expandRequests",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "expected_response",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ClientResponseResult",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "expectedResponse",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "other_allowed_error_codes",
          extendee: nil,
          number: 4,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Code",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "otherAllowedErrorCodes",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [
        %Google.Protobuf.DescriptorProto{
          name: "ExpandedSize",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "size_relative_to_limit",
              extendee: nil,
              number: 1,
              label: :LABEL_OPTIONAL,
              type: :TYPE_INT32,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "sizeRelativeToLimit",
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
              name: "_size_relative_to_limit",
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
      oneof_decl: [],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :request, 1, type: Connectrpc.Conformance.V1.ClientCompatRequest

  field :expand_requests, 2,
    repeated: true,
    type: Connectrpc.Conformance.V1.TestCase.ExpandedSize,
    json_name: "expandRequests"

  field :expected_response, 3,
    type: Connectrpc.Conformance.V1.ClientResponseResult,
    json_name: "expectedResponse"

  field :other_allowed_error_codes, 4,
    repeated: true,
    type: Connectrpc.Conformance.V1.Code,
    json_name: "otherAllowedErrorCodes",
    enum: true
end
