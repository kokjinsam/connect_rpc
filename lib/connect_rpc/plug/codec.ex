defmodule ConnectRPC.Plug.Codec do
  @moduledoc false

  @behaviour Plug

  alias ConnectRPC.Protocol

  @default_codecs [ConnectRPC.Codec.Proto, ConnectRPC.Codec.JSON]

  @impl Plug
  def init(opts) do
    codecs = Keyword.get(opts, :codecs, @default_codecs)
    %{codecs: normalize_codecs!(codecs)}
  end

  @impl Plug
  def call(%Plug.Conn{method: method} = conn, _opts) when method != "POST", do: conn

  def call(conn, %{codecs: codecs}) do
    case Protocol.negotiate_codec(conn, codecs) do
      {:ok, codec} ->
        Plug.Conn.assign(conn, :connect_rpc_codec, codec)

      {:error, error, status} ->
        conn
        |> Protocol.send_error(error, status)
        |> Plug.Conn.halt()
    end
  end

  defp normalize_codecs!(codecs) when is_list(codecs), do: Enum.map(codecs, &validate_codec!/1)

  defp normalize_codecs!(other) do
    raise ArgumentError, "Expected :codecs to be a list of codec modules, got #{inspect(other)}"
  end

  defp validate_codec!(codec) when is_atom(codec) do
    case Code.ensure_compiled(codec) do
      {:module, _module} ->
        validate_codec_callbacks!(codec)
        validate_codec_media_type!(codec)
        codec

      {:error, reason} ->
        raise ArgumentError, "Expected codec module #{inspect(codec)} to be available, got: #{inspect(reason)}"
    end
  end

  defp validate_codec!(codec) do
    raise ArgumentError, "Expected codec entry to be a module, got #{inspect(codec)}"
  end

  defp validate_codec_callbacks!(codec) do
    callbacks = [media_type: 0, encode: 1, decode: 2]

    Enum.each(callbacks, fn {name, arity} ->
      if !function_exported?(codec, name, arity) do
        raise ArgumentError,
              "Codec #{inspect(codec)} must implement #{name}/#{arity}"
      end
    end)
  end

  defp validate_codec_media_type!(codec) do
    media_type = codec.media_type()

    if !is_binary(media_type) or media_type == "" do
      raise ArgumentError,
            "Codec #{inspect(codec)} must return a non-empty binary media type from media_type/0"
    end
  end
end
