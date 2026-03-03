defmodule ConnectRPC.Handler do
  @moduledoc """
  Macro for declaring ConnectRPC service handlers.
  """

  @typedoc false
  @type method_metadata :: %{
          name: String.t(),
          function: atom(),
          request: module(),
          response: module(),
          client_streaming?: boolean(),
          server_streaming?: boolean()
        }

  @typedoc false
  @type service_metadata :: %{
          service_name: String.t(),
          methods: [method_metadata()]
        }

  @doc false
  defmacro __using__(opts) do
    service_module = opts |> Keyword.fetch!(:service) |> Macro.expand(__CALLER__)

    case Code.ensure_compiled(service_module) do
      {:module, _module} ->
        :ok

      _other ->
        raise CompileError,
          description:
            "Module #{inspect(service_module)} must be compiled before #{inspect(__CALLER__.module)}. " <>
              "Ensure your .proto-generated modules compile before your handler modules."
    end

    %{service_name: service_name, methods: methods} = extract_service_metadata!(service_module)

    {unary_methods, streaming_methods} =
      Enum.split_with(methods, fn method ->
        not method.client_streaming? and not method.server_streaming?
      end)

    Enum.each(streaming_methods, fn method ->
      IO.warn(
        "Skipping streaming method #{method.name} - streaming is not yet supported in connect_rpc v0.1.0"
      )
    end)

    escaped_methods = Macro.escape(unary_methods)

    quote do
      @connect_rpc_service_name unquote(service_name)
      @connect_rpc_methods unquote(escaped_methods)

      @before_compile ConnectRPC.Handler

      @doc false
      def __connect_rpc__(:service_name), do: @connect_rpc_service_name

      @doc false
      def __connect_rpc__(:methods), do: Map.new(@connect_rpc_methods, &{&1.name, &1})
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    methods = Module.get_attribute(env.module, :connect_rpc_methods) || []

    service_name =
      Module.get_attribute(env.module, :connect_rpc_service_name) || inspect(env.module)

    missing =
      Enum.reject(methods, fn method ->
        Module.defines?(env.module, {method.function, 2}, :def)
      end)

    case missing do
      [] ->
        quote(do: :ok)

      [method | _rest] ->
        raise CompileError,
          description:
            "#{inspect(env.module)} is missing handler function #{method.function}/2 " <>
              "for RPC method #{method.name} defined in #{service_name}"
    end
  end

  @doc false
  @spec extract_service_metadata!(module()) :: service_metadata()
  def extract_service_metadata!(service_module) when is_atom(service_module) do
    cond do
      function_exported?(service_module, :__connect_rpc_service__, 0) ->
        service_module.__connect_rpc_service__()
        |> normalize_connect_rpc_service(service_module)

      function_exported?(service_module, :__rpcs__, 0) ->
        normalize_grpc_service(service_module)

      function_exported?(service_module, :descriptor, 0) ->
        normalize_descriptor_service(service_module)

      true ->
        raise ArgumentError,
              "Service module #{inspect(service_module)} does not expose supported service metadata. " <>
                "Expected __connect_rpc_service__/0, __rpcs__/0, or descriptor/0."
    end
  end

  defp normalize_connect_rpc_service(service_metadata, service_module) do
    metadata_map =
      case service_metadata do
        map when is_map(map) -> map
        keyword when is_list(keyword) -> Map.new(keyword)
      end

    service_name =
      metadata_map[:name] ||
        metadata_map["name"] ||
        metadata_map[:service_name] ||
        metadata_map["service_name"] ||
        infer_service_name(service_module)

    methods =
      normalize_methods(metadata_map[:methods] || metadata_map["methods"] || [], service_module)

    %{service_name: service_name, methods: methods}
  end

  defp normalize_grpc_service(service_module) do
    service_name =
      cond do
        function_exported?(service_module, :__service_name__, 0) ->
          service_module.__service_name__()

        function_exported?(service_module, :service_name, 0) ->
          service_module.service_name()

        true ->
          infer_service_name(service_module)
      end

    methods =
      service_module
      |> apply(:__rpcs__, [])
      |> normalize_methods(service_module)

    %{service_name: service_name, methods: methods}
  end

  defp normalize_descriptor_service(service_module) do
    descriptor = service_module.descriptor()
    method_descriptors = Map.get(descriptor, :method, [])

    service_name =
      cond do
        function_exported?(service_module, :__service_name__, 0) ->
          service_module.__service_name__()

        function_exported?(service_module, :service_name, 0) ->
          service_module.service_name()

        true ->
          Map.get(descriptor, :name) || infer_service_name(service_module)
      end

    methods =
      Enum.map(method_descriptors, fn method ->
        method_name = method |> Map.get(:name) |> to_string()

        %{
          name: method_name,
          function: method_name |> Macro.underscore() |> String.to_atom(),
          request:
            method
            |> Map.get(:input_type)
            |> resolve_type_module(service_module),
          response:
            method
            |> Map.get(:output_type)
            |> resolve_type_module(service_module),
          client_streaming?: Map.get(method, :client_streaming, false),
          server_streaming?: Map.get(method, :server_streaming, false)
        }
      end)

    %{service_name: service_name, methods: methods}
  end

  defp normalize_methods(methods, service_module) when is_list(methods) do
    Enum.map(methods, &normalize_method(&1, service_module))
  end

  defp normalize_method(rpc, service_module) when is_map(rpc) do
    method_name =
      map_get_any(rpc, [:name, "name", :method, "method"])
      |> to_string()

    request =
      map_get_any(rpc, [:request, "request", :input, "input", :request_type, "request_type"])

    response =
      map_get_any(rpc, [:response, "response", :output, "output", :response_type, "response_type"])

    %{
      name: method_name,
      function: method_name |> Macro.underscore() |> String.to_atom(),
      request: normalize_type_module(request, service_module),
      response: normalize_type_module(response, service_module),
      client_streaming?:
        map_get_any(
          rpc,
          [:client_streaming?, "client_streaming?", :client_streaming, "client_streaming"],
          false
        ),
      server_streaming?:
        map_get_any(
          rpc,
          [:server_streaming?, "server_streaming?", :server_streaming, "server_streaming"],
          false
        )
    }
  end

  defp normalize_method({name, request, response}, service_module) do
    normalize_method(
      %{
        name: name,
        request: request,
        response: response,
        client_streaming?: false,
        server_streaming?: false
      },
      service_module
    )
  end

  defp normalize_method(
         {name, request, response, client_streaming?, server_streaming?},
         service_module
       ) do
    normalize_method(
      %{
        name: name,
        request: request,
        response: response,
        client_streaming?: client_streaming?,
        server_streaming?: server_streaming?
      },
      service_module
    )
  end

  defp normalize_method(other, service_module) do
    raise ArgumentError,
          "Unsupported RPC metadata #{inspect(other)} from #{inspect(service_module)}"
  end

  defp normalize_type_module(module, _service_module) when is_atom(module), do: module

  defp normalize_type_module(type_name, service_module) do
    resolve_type_module(type_name, service_module)
  end

  defp resolve_type_module(type_name, service_module) when is_binary(type_name) do
    cleaned_name = String.trim_leading(type_name, ".")

    candidate =
      cleaned_name
      |> String.split(".")
      |> Enum.map(&Macro.camelize/1)
      |> Module.concat()

    cond do
      Code.ensure_loaded?(candidate) ->
        candidate

      true ->
        segments = String.split(cleaned_name, ".")
        type_leaf = List.last(segments) |> Macro.camelize()
        namespace = service_module |> Module.split() |> Enum.drop(-1)
        nested_candidate = Module.concat(namespace ++ [type_leaf])

        if Code.ensure_loaded?(nested_candidate) do
          nested_candidate
        else
          raise ArgumentError,
                "Unable to resolve protobuf type #{inspect(type_name)} for service #{inspect(service_module)}"
        end
    end
  end

  defp resolve_type_module(type_name, service_module) do
    raise ArgumentError,
          "Unsupported protobuf type #{inspect(type_name)} for service #{inspect(service_module)}"
  end

  defp map_get_any(map, keys, default \\ nil) do
    Enum.find_value(keys, default, fn key ->
      if Map.has_key?(map, key), do: Map.get(map, key)
    end)
  end

  defp infer_service_name(service_module) do
    service_module
    |> Module.split()
    |> List.last()
    |> to_string()
  end
end
