defmodule ConnectRPC.Router do
  @moduledoc """
  Router DSL for ConnectRPC services.
  """

  defmacro __using__(_opts) do
    quote do
      import ConnectRPC.Router, only: [service: 3, service: 4, rpc: 3]

      Module.register_attribute(__MODULE__, :connect_rpc_routes, accumulate: true)
      Module.register_attribute(__MODULE__, :connect_rpc_current_handler, [])
      Module.register_attribute(__MODULE__, :connect_rpc_current_service_name, [])

      @before_compile ConnectRPC.Router
    end
  end

  defmacro service(path, handler, do: block) do
    quote do
      service(unquote(path), unquote(handler), [], do: unquote(block))
    end
  end

  defmacro service(path, handler, opts, do: block) do
    caller = __CALLER__

    expanded_opts = Macro.expand(opts, caller)

    if !is_list(expanded_opts) do
      raise ArgumentError,
            "Expected service options to be a keyword list, got #{inspect(expanded_opts)}"
    end

    handler_module = Macro.expand(handler, caller)
    service_name = strip_leading_slash(path)
    pipeline_name = generate_pipeline_name(caller.module, path, handler_module, caller.line)

    codecs = Keyword.get(expanded_opts, :codecs)
    read_body_opts = Keyword.get(expanded_opts, :read_body_opts)
    read_body_fun = Keyword.get(expanded_opts, :read_body_fun)

    codec_opts = if is_nil(codecs), do: [], else: [codecs: codecs]

    decoder_opts =
      []
      |> maybe_put_opt(:read_body_opts, read_body_opts)
      |> maybe_put_opt(:read_body_fun, read_body_fun)

    Module.put_attribute(caller.module, :connect_rpc_current_handler, handler_module)
    Module.put_attribute(caller.module, :connect_rpc_current_service_name, service_name)

    quote do
      pipeline unquote(pipeline_name) do
        plug(ConnectRPC.Plug.Context)
        # Keep method validation in Validator while preserving content-type precedence for POST.
        plug(ConnectRPC.Plug.Codec, unquote(codec_opts))
        plug(ConnectRPC.Plug.Validator)
        plug(ConnectRPC.Plug.Decoder, unquote(decoder_opts))
      end

      scope unquote(path) do
        pipe_through(unquote(pipeline_name))
        unquote(block)
      end

      Module.delete_attribute(__MODULE__, :connect_rpc_current_handler)
      Module.delete_attribute(__MODULE__, :connect_rpc_current_service_name)
    end
  end

  defmacro rpc(path, action, opts) do
    caller = __CALLER__

    expanded_opts = Macro.expand(opts, caller)

    if !is_list(expanded_opts) do
      raise ArgumentError, "Expected rpc options to be a keyword list, got #{inspect(expanded_opts)}"
    end

    request = expanded_opts |> Keyword.fetch!(:request) |> Macro.expand(caller)
    response = expanded_opts |> Keyword.fetch!(:response) |> Macro.expand(caller)

    handler = Module.get_attribute(caller.module, :connect_rpc_current_handler)
    service_name = Module.get_attribute(caller.module, :connect_rpc_current_service_name)

    if is_nil(handler) or is_nil(service_name) do
      raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "rpc/3 must be called inside a service/3 or service/4 block"
    end

    ensure_module_compiled!(request, "request", caller)
    ensure_module_compiled!(response, "response", caller)

    case Code.ensure_compiled(handler) do
      {:module, _module} ->
        if !function_exported?(handler, action, 2) do
          raise CompileError,
            file: caller.file,
            line: caller.line,
            description: "undefined function #{inspect(handler)}.#{action}/2"
        end

      {:error, _reason} ->
        :ok
    end

    Module.put_attribute(caller.module, :connect_rpc_routes, %{line: caller.line, handler: handler, action: action})

    method_name = method_name_from_path_or_action(path, action)

    quote do
      match(:*, unquote(path), unquote(handler), unquote(action),
        private: %{
          connect_rpc_rpc: %{
            request: unquote(request),
            response: unquote(response),
            action: unquote(action),
            service_name: unquote(service_name),
            method_name: unquote(method_name)
          }
        }
      )
    end
  end

  defmacro __before_compile__(env) do
    routes = Module.get_attribute(env.module, :connect_rpc_routes) || []

    Enum.each(routes, fn %{line: line, handler: handler, action: action} ->
      case Code.ensure_compiled(handler) do
        {:module, _module} ->
          :ok

        {:error, _reason} ->
          raise CompileError,
            file: env.file,
            line: line,
            description:
              "Module #{inspect(handler)} must be compiled before #{inspect(env.module)}. " <>
                "Ensure your handler module is available when defining ConnectRPC routes."
      end

      if !function_exported?(handler, action, 2) do
        raise CompileError,
          file: env.file,
          line: line,
          description: "undefined function #{inspect(handler)}.#{action}/2"
      end
    end)

    quote(do: :ok)
  end

  defp generate_pipeline_name(router_module, path, handler, line) do
    suffix = :erlang.phash2({router_module, path, handler, line})
    String.to_atom("connect_rpc_#{suffix}")
  end

  defp strip_leading_slash(path) when is_binary(path), do: String.trim_leading(path, "/")

  defp strip_leading_slash(path) do
    raise ArgumentError, "Expected service path to be a binary, got #{inspect(path)}"
  end

  defp method_name_from_path_or_action(path, action) when is_binary(path) do
    case String.trim_leading(path, "/") do
      "" -> action |> Atom.to_string() |> Macro.camelize()
      method_name -> method_name
    end
  end

  defp maybe_put_opt(opts, _key, nil), do: opts
  defp maybe_put_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp ensure_module_compiled!(module, role, caller) do
    case Code.ensure_compiled(module) do
      {:module, _module} ->
        :ok

      {:error, _reason} ->
        raise CompileError,
          file: caller.file,
          line: caller.line,
          description: "Expected #{role} module #{inspect(module)} to be compiled before defining this rpc/3 route"
    end
  end
end
