defmodule Connectrpc.Conformance.V1.HTTPVersion do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.HTTPVersion",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "HTTPVersion",
      value: [
        %EnumValueDescriptorProto{
          name: "HTTP_VERSION_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "HTTP_VERSION_1",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "HTTP_VERSION_2",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "HTTP_VERSION_3",
          number: 3,
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

  field(:HTTP_VERSION_UNSPECIFIED, 0)
  field(:HTTP_VERSION_1, 1)
  field(:HTTP_VERSION_2, 2)
  field(:HTTP_VERSION_3, 3)
end

defmodule Connectrpc.Conformance.V1.Protocol do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.Protocol",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "Protocol",
      value: [
        %EnumValueDescriptorProto{
          name: "PROTOCOL_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "PROTOCOL_CONNECT",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "PROTOCOL_GRPC",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "PROTOCOL_GRPC_WEB",
          number: 3,
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

  field(:PROTOCOL_UNSPECIFIED, 0)
  field(:PROTOCOL_CONNECT, 1)
  field(:PROTOCOL_GRPC, 2)
  field(:PROTOCOL_GRPC_WEB, 3)
end

defmodule Connectrpc.Conformance.V1.Codec do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.Codec",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "Codec",
      value: [
        %EnumValueDescriptorProto{
          name: "CODEC_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODEC_PROTO",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODEC_JSON",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODEC_TEXT",
          number: 3,
          options: %Google.Protobuf.EnumValueOptions{
            deprecated: true,
            features: nil,
            debug_redact: false,
            feature_support: nil,
            uninterpreted_option: [],
            __pb_extensions__: %{},
            __unknown_fields__: []
          },
          __unknown_fields__: []
        }
      ],
      options: nil,
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field(:CODEC_UNSPECIFIED, 0)
  field(:CODEC_PROTO, 1)
  field(:CODEC_JSON, 2)
  field(:CODEC_TEXT, 3)
end

defmodule Connectrpc.Conformance.V1.Compression do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.Compression",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "Compression",
      value: [
        %EnumValueDescriptorProto{
          name: "COMPRESSION_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_IDENTITY",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_GZIP",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_BR",
          number: 3,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_ZSTD",
          number: 4,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_DEFLATE",
          number: 5,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "COMPRESSION_SNAPPY",
          number: 6,
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

  field(:COMPRESSION_UNSPECIFIED, 0)
  field(:COMPRESSION_IDENTITY, 1)
  field(:COMPRESSION_GZIP, 2)
  field(:COMPRESSION_BR, 3)
  field(:COMPRESSION_ZSTD, 4)
  field(:COMPRESSION_DEFLATE, 5)
  field(:COMPRESSION_SNAPPY, 6)
end

defmodule Connectrpc.Conformance.V1.StreamType do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.StreamType",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "StreamType",
      value: [
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_UNARY",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_CLIENT_STREAM",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_SERVER_STREAM",
          number: 3,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_HALF_DUPLEX_BIDI_STREAM",
          number: 4,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "STREAM_TYPE_FULL_DUPLEX_BIDI_STREAM",
          number: 5,
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

  field(:STREAM_TYPE_UNSPECIFIED, 0)
  field(:STREAM_TYPE_UNARY, 1)
  field(:STREAM_TYPE_CLIENT_STREAM, 2)
  field(:STREAM_TYPE_SERVER_STREAM, 3)
  field(:STREAM_TYPE_HALF_DUPLEX_BIDI_STREAM, 4)
  field(:STREAM_TYPE_FULL_DUPLEX_BIDI_STREAM, 5)
end

defmodule Connectrpc.Conformance.V1.Code do
  @moduledoc false

  use Protobuf,
    enum: true,
    full_name: "connectrpc.conformance.v1.Code",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.EnumValueDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.EnumDescriptorProto{
      name: "Code",
      value: [
        %EnumValueDescriptorProto{
          name: "CODE_UNSPECIFIED",
          number: 0,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_CANCELED",
          number: 1,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_UNKNOWN",
          number: 2,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_INVALID_ARGUMENT",
          number: 3,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_DEADLINE_EXCEEDED",
          number: 4,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_NOT_FOUND",
          number: 5,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_ALREADY_EXISTS",
          number: 6,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_PERMISSION_DENIED",
          number: 7,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_RESOURCE_EXHAUSTED",
          number: 8,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_FAILED_PRECONDITION",
          number: 9,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_ABORTED",
          number: 10,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_OUT_OF_RANGE",
          number: 11,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_UNIMPLEMENTED",
          number: 12,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_INTERNAL",
          number: 13,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_UNAVAILABLE",
          number: 14,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_DATA_LOSS",
          number: 15,
          options: nil,
          __unknown_fields__: []
        },
        %EnumValueDescriptorProto{
          name: "CODE_UNAUTHENTICATED",
          number: 16,
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

  field(:CODE_UNSPECIFIED, 0)
  field(:CODE_CANCELED, 1)
  field(:CODE_UNKNOWN, 2)
  field(:CODE_INVALID_ARGUMENT, 3)
  field(:CODE_DEADLINE_EXCEEDED, 4)
  field(:CODE_NOT_FOUND, 5)
  field(:CODE_ALREADY_EXISTS, 6)
  field(:CODE_PERMISSION_DENIED, 7)
  field(:CODE_RESOURCE_EXHAUSTED, 8)
  field(:CODE_FAILED_PRECONDITION, 9)
  field(:CODE_ABORTED, 10)
  field(:CODE_OUT_OF_RANGE, 11)
  field(:CODE_UNIMPLEMENTED, 12)
  field(:CODE_INTERNAL, 13)
  field(:CODE_UNAVAILABLE, 14)
  field(:CODE_DATA_LOSS, 15)
  field(:CODE_UNAUTHENTICATED, 16)
end

defmodule Connectrpc.Conformance.V1.Config do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.Config",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Connectrpc.Conformance.V1.ConfigCase
  alias Google.Protobuf.FieldDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Config",
      field: [
        %FieldDescriptorProto{
          name: "features",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Features",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "features",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "include_cases",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConfigCase",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "includeCases",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "exclude_cases",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConfigCase",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "excludeCases",
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

  field(:features, 1, type: Connectrpc.Conformance.V1.Features)

  field(:include_cases, 2,
    repeated: true,
    type: ConfigCase,
    json_name: "includeCases"
  )

  field(:exclude_cases, 3,
    repeated: true,
    type: ConfigCase,
    json_name: "excludeCases"
  )
end

defmodule Connectrpc.Conformance.V1.Features do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.Features",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.FieldDescriptorProto
  alias Google.Protobuf.OneofDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Features",
      field: [
        %FieldDescriptorProto{
          name: "versions",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.HTTPVersion",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "versions",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "protocols",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Protocol",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "protocols",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "codecs",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Codec",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "codecs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "compressions",
          extendee: nil,
          number: 4,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Compression",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "compressions",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "stream_types",
          extendee: nil,
          number: 5,
          label: :LABEL_REPEATED,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.StreamType",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "streamTypes",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_h2c",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "supportsH2c",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_tls",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 1,
          json_name: "supportsTls",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_tls_client_certs",
          extendee: nil,
          number: 8,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 2,
          json_name: "supportsTlsClientCerts",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_trailers",
          extendee: nil,
          number: 9,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 3,
          json_name: "supportsTrailers",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_half_duplex_bidi_over_http1",
          extendee: nil,
          number: 10,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 4,
          json_name: "supportsHalfDuplexBidiOverHttp1",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_connect_get",
          extendee: nil,
          number: 11,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 5,
          json_name: "supportsConnectGet",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "supports_message_receive_limit",
          extendee: nil,
          number: 12,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 6,
          json_name: "supportsMessageReceiveLimit",
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
        %OneofDescriptorProto{
          name: "_supports_h2c",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_tls",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_tls_client_certs",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_trailers",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_half_duplex_bidi_over_http1",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_connect_get",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_supports_message_receive_limit",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field(:versions, 1, repeated: true, type: Connectrpc.Conformance.V1.HTTPVersion, enum: true)
  field(:protocols, 2, repeated: true, type: Connectrpc.Conformance.V1.Protocol, enum: true)
  field(:codecs, 3, repeated: true, type: Connectrpc.Conformance.V1.Codec, enum: true)
  field(:compressions, 4, repeated: true, type: Connectrpc.Conformance.V1.Compression, enum: true)

  field(:stream_types, 5,
    repeated: true,
    type: Connectrpc.Conformance.V1.StreamType,
    json_name: "streamTypes",
    enum: true
  )

  field(:supports_h2c, 6, proto3_optional: true, type: :bool, json_name: "supportsH2c")
  field(:supports_tls, 7, proto3_optional: true, type: :bool, json_name: "supportsTls")

  field(:supports_tls_client_certs, 8,
    proto3_optional: true,
    type: :bool,
    json_name: "supportsTlsClientCerts"
  )

  field(:supports_trailers, 9, proto3_optional: true, type: :bool, json_name: "supportsTrailers")

  field(:supports_half_duplex_bidi_over_http1, 10,
    proto3_optional: true,
    type: :bool,
    json_name: "supportsHalfDuplexBidiOverHttp1"
  )

  field(:supports_connect_get, 11,
    proto3_optional: true,
    type: :bool,
    json_name: "supportsConnectGet"
  )

  field(:supports_message_receive_limit, 12,
    proto3_optional: true,
    type: :bool,
    json_name: "supportsMessageReceiveLimit"
  )
end

defmodule Connectrpc.Conformance.V1.ConfigCase do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ConfigCase",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.FieldDescriptorProto
  alias Google.Protobuf.OneofDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ConfigCase",
      field: [
        %FieldDescriptorProto{
          name: "version",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.HTTPVersion",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "version",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "protocol",
          extendee: nil,
          number: 2,
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
        %FieldDescriptorProto{
          name: "codec",
          extendee: nil,
          number: 3,
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
        %FieldDescriptorProto{
          name: "compression",
          extendee: nil,
          number: 4,
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
        %FieldDescriptorProto{
          name: "stream_type",
          extendee: nil,
          number: 5,
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
        %FieldDescriptorProto{
          name: "use_tls",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "useTls",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "use_tls_client_certs",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 1,
          json_name: "useTlsClientCerts",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "use_message_receive_limit",
          extendee: nil,
          number: 8,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 2,
          json_name: "useMessageReceiveLimit",
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
        %OneofDescriptorProto{
          name: "_use_tls",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_use_tls_client_certs",
          options: nil,
          __unknown_fields__: []
        },
        %OneofDescriptorProto{
          name: "_use_message_receive_limit",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field(:version, 1, type: Connectrpc.Conformance.V1.HTTPVersion, enum: true)
  field(:protocol, 2, type: Connectrpc.Conformance.V1.Protocol, enum: true)
  field(:codec, 3, type: Connectrpc.Conformance.V1.Codec, enum: true)
  field(:compression, 4, type: Connectrpc.Conformance.V1.Compression, enum: true)

  field(:stream_type, 5,
    type: Connectrpc.Conformance.V1.StreamType,
    json_name: "streamType",
    enum: true
  )

  field(:use_tls, 6, proto3_optional: true, type: :bool, json_name: "useTls")

  field(:use_tls_client_certs, 7,
    proto3_optional: true,
    type: :bool,
    json_name: "useTlsClientCerts"
  )

  field(:use_message_receive_limit, 8,
    proto3_optional: true,
    type: :bool,
    json_name: "useMessageReceiveLimit"
  )
end

defmodule Connectrpc.Conformance.V1.TLSCreds do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.TLSCreds",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  alias Google.Protobuf.FieldDescriptorProto

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "TLSCreds",
      field: [
        %FieldDescriptorProto{
          name: "cert",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "cert",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %FieldDescriptorProto{
          name: "key",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "key",
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

  field(:cert, 1, type: :bytes)
  field(:key, 2, type: :bytes)
end
