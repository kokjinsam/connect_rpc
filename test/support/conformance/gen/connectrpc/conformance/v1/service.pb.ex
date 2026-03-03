defmodule Connectrpc.Conformance.V1.UnaryResponseDefinition do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.UnaryResponseDefinition",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "UnaryResponseDefinition",
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
          name: "response_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "responseData",
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
          oneof_index: 0,
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
          name: "response_delay_ms",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDelayMs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "raw_response",
          extendee: nil,
          number: 5,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.RawHTTPResponse",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "rawResponse",
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
          name: "response",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :response, 0

  field :response_headers, 1,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseHeaders"

  field :response_data, 2, type: :bytes, json_name: "responseData", oneof: 0
  field :error, 3, type: Connectrpc.Conformance.V1.Error, oneof: 0

  field :response_trailers, 4,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseTrailers"

  field :response_delay_ms, 6, type: :uint32, json_name: "responseDelayMs"

  field :raw_response, 5,
    type: Connectrpc.Conformance.V1.RawHTTPResponse,
    json_name: "rawResponse"
end

defmodule Connectrpc.Conformance.V1.StreamResponseDefinition do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.StreamResponseDefinition",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "StreamResponseDefinition",
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
          name: "response_data",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseData",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_delay_ms",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDelayMs",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "error",
          extendee: nil,
          number: 4,
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
          number: 5,
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
          name: "raw_response",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.RawHTTPResponse",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "rawResponse",
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

  field :response_headers, 1,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseHeaders"

  field :response_data, 2, repeated: true, type: :bytes, json_name: "responseData"
  field :response_delay_ms, 3, type: :uint32, json_name: "responseDelayMs"
  field :error, 4, type: Connectrpc.Conformance.V1.Error

  field :response_trailers, 5,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "responseTrailers"

  field :raw_response, 6,
    type: Connectrpc.Conformance.V1.RawHTTPResponse,
    json_name: "rawResponse"
end

defmodule Connectrpc.Conformance.V1.UnaryRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.UnaryRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "UnaryRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_definition",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.UnaryResponseDefinition",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDefinition",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestData",
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

  field :response_definition, 1,
    type: Connectrpc.Conformance.V1.UnaryResponseDefinition,
    json_name: "responseDefinition"

  field :request_data, 2, type: :bytes, json_name: "requestData"
end

defmodule Connectrpc.Conformance.V1.UnaryResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.UnaryResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "UnaryResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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

  field :payload, 1, type: Connectrpc.Conformance.V1.ConformancePayload
end

defmodule Connectrpc.Conformance.V1.IdempotentUnaryRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.IdempotentUnaryRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "IdempotentUnaryRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_definition",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.UnaryResponseDefinition",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDefinition",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestData",
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

  field :response_definition, 1,
    type: Connectrpc.Conformance.V1.UnaryResponseDefinition,
    json_name: "responseDefinition"

  field :request_data, 2, type: :bytes, json_name: "requestData"
end

defmodule Connectrpc.Conformance.V1.IdempotentUnaryResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.IdempotentUnaryResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "IdempotentUnaryResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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

  field :payload, 1, type: Connectrpc.Conformance.V1.ConformancePayload
end

defmodule Connectrpc.Conformance.V1.ServerStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ServerStreamRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerStreamRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_definition",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.StreamResponseDefinition",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDefinition",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestData",
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

  field :response_definition, 1,
    type: Connectrpc.Conformance.V1.StreamResponseDefinition,
    json_name: "responseDefinition"

  field :request_data, 2, type: :bytes, json_name: "requestData"
end

defmodule Connectrpc.Conformance.V1.ServerStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ServerStreamResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ServerStreamResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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

  field :payload, 1, type: Connectrpc.Conformance.V1.ConformancePayload
end

defmodule Connectrpc.Conformance.V1.ClientStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientStreamRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientStreamRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_definition",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.UnaryResponseDefinition",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDefinition",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_data",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestData",
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

  field :response_definition, 1,
    type: Connectrpc.Conformance.V1.UnaryResponseDefinition,
    json_name: "responseDefinition"

  field :request_data, 2, type: :bytes, json_name: "requestData"
end

defmodule Connectrpc.Conformance.V1.ClientStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ClientStreamResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ClientStreamResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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

  field :payload, 1, type: Connectrpc.Conformance.V1.ConformancePayload
end

defmodule Connectrpc.Conformance.V1.BidiStreamRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.BidiStreamRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BidiStreamRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "response_definition",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.StreamResponseDefinition",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "responseDefinition",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "full_duplex",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "fullDuplex",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_data",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestData",
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

  field :response_definition, 1,
    type: Connectrpc.Conformance.V1.StreamResponseDefinition,
    json_name: "responseDefinition"

  field :full_duplex, 2, type: :bool, json_name: "fullDuplex"
  field :request_data, 3, type: :bytes, json_name: "requestData"
end

defmodule Connectrpc.Conformance.V1.BidiStreamResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.BidiStreamResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "BidiStreamResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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

  field :payload, 1, type: Connectrpc.Conformance.V1.ConformancePayload
end

defmodule Connectrpc.Conformance.V1.UnimplementedRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.UnimplementedRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "UnimplementedRequest",
      field: [],
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
end

defmodule Connectrpc.Conformance.V1.UnimplementedResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.UnimplementedResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "UnimplementedResponse",
      field: [],
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
end

defmodule Connectrpc.Conformance.V1.ConformancePayload.RequestInfo do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ConformancePayload.RequestInfo",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "RequestInfo",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_headers",
          extendee: nil,
          number: 1,
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
          name: "timeout_ms",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_INT64,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "timeoutMs",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "requests",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requests",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "connect_get_info",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload.ConnectGetInfo",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "connectGetInfo",
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

  field :request_headers, 1,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "requestHeaders"

  field :timeout_ms, 2, proto3_optional: true, type: :int64, json_name: "timeoutMs"
  field :requests, 3, repeated: true, type: Google.Protobuf.Any

  field :connect_get_info, 4,
    type: Connectrpc.Conformance.V1.ConformancePayload.ConnectGetInfo,
    json_name: "connectGetInfo"
end

defmodule Connectrpc.Conformance.V1.ConformancePayload.ConnectGetInfo do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ConformancePayload.ConnectGetInfo",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ConnectGetInfo",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "query_params",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "queryParams",
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

  field :query_params, 1,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "queryParams"
end

defmodule Connectrpc.Conformance.V1.ConformancePayload do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.ConformancePayload",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "ConformancePayload",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "data",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "data",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "request_info",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.ConformancePayload.RequestInfo",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "requestInfo",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [
        %Google.Protobuf.DescriptorProto{
          name: "RequestInfo",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "request_headers",
              extendee: nil,
              number: 1,
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
              name: "timeout_ms",
              extendee: nil,
              number: 2,
              label: :LABEL_OPTIONAL,
              type: :TYPE_INT64,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "timeoutMs",
              proto3_optional: true,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "requests",
              extendee: nil,
              number: 3,
              label: :LABEL_REPEATED,
              type: :TYPE_MESSAGE,
              type_name: ".google.protobuf.Any",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "requests",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "connect_get_info",
              extendee: nil,
              number: 4,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".connectrpc.conformance.v1.ConformancePayload.ConnectGetInfo",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "connectGetInfo",
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
              name: "_timeout_ms",
              options: nil,
              __unknown_fields__: []
            }
          ],
          reserved_range: [],
          reserved_name: [],
          __unknown_fields__: []
        },
        %Google.Protobuf.DescriptorProto{
          name: "ConnectGetInfo",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "query_params",
              extendee: nil,
              number: 1,
              label: :LABEL_REPEATED,
              type: :TYPE_MESSAGE,
              type_name: ".connectrpc.conformance.v1.Header",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "queryParams",
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

  field :data, 1, type: :bytes

  field :request_info, 2,
    type: Connectrpc.Conformance.V1.ConformancePayload.RequestInfo,
    json_name: "requestInfo"
end

defmodule Connectrpc.Conformance.V1.Error do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.Error",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Error",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "code",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_ENUM,
          type_name: ".connectrpc.conformance.v1.Code",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "code",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "message",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "message",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "details",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "details",
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
          name: "_message",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :code, 1, type: Connectrpc.Conformance.V1.Code, enum: true
  field :message, 2, proto3_optional: true, type: :string
  field :details, 3, repeated: true, type: Google.Protobuf.Any
end

defmodule Connectrpc.Conformance.V1.Header do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.Header",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "Header",
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
          name: "value",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "value",
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

  field :name, 1, type: :string
  field :value, 2, repeated: true, type: :string
end

defmodule Connectrpc.Conformance.V1.RawHTTPRequest.EncodedQueryParam do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.RawHTTPRequest.EncodedQueryParam",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "EncodedQueryParam",
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
          name: "value",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.MessageContents",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "value",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "base64_encode",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BOOL,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "base64Encode",
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

  field :name, 1, type: :string
  field :value, 2, type: Connectrpc.Conformance.V1.MessageContents
  field :base64_encode, 3, type: :bool, json_name: "base64Encode"
end

defmodule Connectrpc.Conformance.V1.RawHTTPRequest do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.RawHTTPRequest",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "RawHTTPRequest",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "verb",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "verb",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "uri",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "uri",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "headers",
          extendee: nil,
          number: 3,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "headers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "raw_query_params",
          extendee: nil,
          number: 4,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "rawQueryParams",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "encoded_query_params",
          extendee: nil,
          number: 5,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.RawHTTPRequest.EncodedQueryParam",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "encodedQueryParams",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "unary",
          extendee: nil,
          number: 6,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.MessageContents",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "unary",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "stream",
          extendee: nil,
          number: 7,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.StreamContents",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "stream",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [
        %Google.Protobuf.DescriptorProto{
          name: "EncodedQueryParam",
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
              name: "value",
              extendee: nil,
              number: 2,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".connectrpc.conformance.v1.MessageContents",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "value",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "base64_encode",
              extendee: nil,
              number: 3,
              label: :LABEL_OPTIONAL,
              type: :TYPE_BOOL,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "base64Encode",
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
      ],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{name: "body", options: nil, __unknown_fields__: []}
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :body, 0

  field :verb, 1, type: :string
  field :uri, 2, type: :string
  field :headers, 3, repeated: true, type: Connectrpc.Conformance.V1.Header

  field :raw_query_params, 4,
    repeated: true,
    type: Connectrpc.Conformance.V1.Header,
    json_name: "rawQueryParams"

  field :encoded_query_params, 5,
    repeated: true,
    type: Connectrpc.Conformance.V1.RawHTTPRequest.EncodedQueryParam,
    json_name: "encodedQueryParams"

  field :unary, 6, type: Connectrpc.Conformance.V1.MessageContents, oneof: 0
  field :stream, 7, type: Connectrpc.Conformance.V1.StreamContents, oneof: 0
end

defmodule Connectrpc.Conformance.V1.MessageContents do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.MessageContents",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "MessageContents",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "binary",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_BYTES,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "binary",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "text",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_STRING,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "text",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "binary_message",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".google.protobuf.Any",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "binaryMessage",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
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
        }
      ],
      nested_type: [],
      enum_type: [],
      extension_range: [],
      extension: [],
      options: nil,
      oneof_decl: [
        %Google.Protobuf.OneofDescriptorProto{name: "data", options: nil, __unknown_fields__: []}
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :data, 0

  field :binary, 1, type: :bytes, oneof: 0
  field :text, 2, type: :string, oneof: 0
  field :binary_message, 3, type: Google.Protobuf.Any, json_name: "binaryMessage", oneof: 0
  field :compression, 4, type: Connectrpc.Conformance.V1.Compression, enum: true
end

defmodule Connectrpc.Conformance.V1.StreamContents.StreamItem do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.StreamContents.StreamItem",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "StreamItem",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "flags",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "flags",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "length",
          extendee: nil,
          number: 2,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "length",
          proto3_optional: true,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "payload",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.MessageContents",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "payload",
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
          name: "_length",
          options: nil,
          __unknown_fields__: []
        }
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  field :flags, 1, type: :uint32
  field :length, 2, proto3_optional: true, type: :uint32
  field :payload, 3, type: Connectrpc.Conformance.V1.MessageContents
end

defmodule Connectrpc.Conformance.V1.StreamContents do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.StreamContents",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "StreamContents",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "items",
          extendee: nil,
          number: 1,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.StreamContents.StreamItem",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "items",
          proto3_optional: nil,
          __unknown_fields__: []
        }
      ],
      nested_type: [
        %Google.Protobuf.DescriptorProto{
          name: "StreamItem",
          field: [
            %Google.Protobuf.FieldDescriptorProto{
              name: "flags",
              extendee: nil,
              number: 1,
              label: :LABEL_OPTIONAL,
              type: :TYPE_UINT32,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "flags",
              proto3_optional: nil,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "length",
              extendee: nil,
              number: 2,
              label: :LABEL_OPTIONAL,
              type: :TYPE_UINT32,
              type_name: nil,
              default_value: nil,
              options: nil,
              oneof_index: 0,
              json_name: "length",
              proto3_optional: true,
              __unknown_fields__: []
            },
            %Google.Protobuf.FieldDescriptorProto{
              name: "payload",
              extendee: nil,
              number: 3,
              label: :LABEL_OPTIONAL,
              type: :TYPE_MESSAGE,
              type_name: ".connectrpc.conformance.v1.MessageContents",
              default_value: nil,
              options: nil,
              oneof_index: nil,
              json_name: "payload",
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
              name: "_length",
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

  field :items, 1, repeated: true, type: Connectrpc.Conformance.V1.StreamContents.StreamItem
end

defmodule Connectrpc.Conformance.V1.RawHTTPResponse do
  @moduledoc false

  use Protobuf,
    full_name: "connectrpc.conformance.v1.RawHTTPResponse",
    protoc_gen_elixir_version: "0.16.0",
    syntax: :proto3

  def descriptor do
    # credo:disable-for-next-line
    %Google.Protobuf.DescriptorProto{
      name: "RawHTTPResponse",
      field: [
        %Google.Protobuf.FieldDescriptorProto{
          name: "status_code",
          extendee: nil,
          number: 1,
          label: :LABEL_OPTIONAL,
          type: :TYPE_UINT32,
          type_name: nil,
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "statusCode",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "headers",
          extendee: nil,
          number: 2,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "headers",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "unary",
          extendee: nil,
          number: 3,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.MessageContents",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "unary",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "stream",
          extendee: nil,
          number: 4,
          label: :LABEL_OPTIONAL,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.StreamContents",
          default_value: nil,
          options: nil,
          oneof_index: 0,
          json_name: "stream",
          proto3_optional: nil,
          __unknown_fields__: []
        },
        %Google.Protobuf.FieldDescriptorProto{
          name: "trailers",
          extendee: nil,
          number: 5,
          label: :LABEL_REPEATED,
          type: :TYPE_MESSAGE,
          type_name: ".connectrpc.conformance.v1.Header",
          default_value: nil,
          options: nil,
          oneof_index: nil,
          json_name: "trailers",
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
        %Google.Protobuf.OneofDescriptorProto{name: "body", options: nil, __unknown_fields__: []}
      ],
      reserved_range: [],
      reserved_name: [],
      __unknown_fields__: []
    }
  end

  oneof :body, 0

  field :status_code, 1, type: :uint32, json_name: "statusCode"
  field :headers, 2, repeated: true, type: Connectrpc.Conformance.V1.Header
  field :unary, 3, type: Connectrpc.Conformance.V1.MessageContents, oneof: 0
  field :stream, 4, type: Connectrpc.Conformance.V1.StreamContents, oneof: 0
  field :trailers, 5, repeated: true, type: Connectrpc.Conformance.V1.Header
end
