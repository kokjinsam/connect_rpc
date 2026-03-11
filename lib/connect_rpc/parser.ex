defmodule ConnectRPC.Parser do
  @moduledoc false

  @behaviour Plug.Parsers

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.Error
  alias ConnectRPC.Protocol

  @default_codecs [ConnectRPC.Codec.Proto, JSON]

  @impl Plug.Parsers
  def init(opts) do
    codecs = Keyword.get(opts, :codecs, @default_codecs)
    read_body_opts = Keyword.take(opts, [:length, :read_length, :read_timeout])
    %{codecs: normalize_codecs!(codecs), read_body_opts: read_body_opts}
  end

  @impl Plug.Parsers
  def parse(conn, _type, _subtype, _params, %{codecs: codecs, read_body_opts: read_body_opts}) do
    case Protocol.validate_protocol_version(conn) do
      :ok ->
        parse_connect_request(conn, codecs, read_body_opts)

      {:error, _error, _status} ->
        {:next, conn}
    end
  end

  defp parse_connect_request(conn, codecs, read_body_opts) do
    with :ok <- Protocol.validate_post(conn),
         :ok <- Protocol.validate_compression(conn),
         {:ok, codec} <- Protocol.negotiate_codec(conn, codecs),
         conn = Plug.Conn.assign(conn, :connect_rpc_codec, codec),
         {:ok, body, conn} <- read_body(conn, read_body_opts),
         {:ok, body_params, conn} <- decode_body(conn, codec, body) do
      conn =
        conn
        |> Plug.Conn.put_private(:connect_rpc_valid, true)
        |> Plug.Conn.put_private(:connect_rpc_errors, [])

      {:ok, body_params, conn}
    else
      {:error, :too_large, conn} ->
        {:error, :too_large, conn}

      {:error, error, status, conn} ->
        conn = put_connect_error(conn, {:error, error, status})
        {:ok, %{}, conn}

      {:error, error, status} ->
        conn = put_connect_error(conn, {:error, error, status})
        {:ok, %{}, conn}
    end
  end

  defp decode_body(conn, codec, body) do
    case codec do
      JSON ->
        conn = Plug.Conn.put_private(conn, :connect_rpc_body_format, :json_map)

        case decode_json(body) do
          {:ok, decoded} ->
            {:ok, decoded, conn}

          {:error, _reason} ->
            {:error, Error.new(:invalid_argument, "Invalid request body"), 400}
        end

      _other ->
        conn = Plug.Conn.put_private(conn, :connect_rpc_body_format, :raw_binary)
        {:ok, %{"_raw" => body}, conn}
    end
  end

  defp decode_json(body) do
    case Jason.decode(body) do
      {:ok, %{} = decoded} -> {:ok, decoded}
      {:ok, _decoded} -> {:error, :non_object_json}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} -> {:ok, body, conn}
      {:more, _chunk, conn} -> {:error, :too_large, conn}
      {:error, reason} -> {:error, Error.new(:internal, inspect(reason)), 500, conn}
    end
  end

  defp put_connect_error(conn, {:error, error, status}) do
    conn
    |> Plug.Conn.put_private(:connect_rpc_valid, false)
    |> Plug.Conn.put_private(:connect_rpc_errors, [{error, status}])
    |> Plug.Conn.put_private(:connect_rpc_body_format, nil)
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
