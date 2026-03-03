defmodule ConnectRPC.Protocol do
  @moduledoc false

  import Plug.Conn

  alias ConnectRPC.Codec.JSON
  alias ConnectRPC.Codec.Proto
  alias ConnectRPC.Error

  @status_by_code %{
    canceled: 499,
    unknown: 500,
    invalid_argument: 400,
    deadline_exceeded: 504,
    not_found: 404,
    already_exists: 409,
    permission_denied: 403,
    resource_exhausted: 429,
    failed_precondition: 400,
    aborted: 409,
    out_of_range: 400,
    unimplemented: 501,
    internal: 500,
    unavailable: 503,
    data_loss: 500,
    unauthenticated: 401
  }

  @doc """
  Validates a unary request uses `POST`.
  """
  @spec validate_post(Plug.Conn.t()) :: :ok | {:error, Error.t(), pos_integer()}
  def validate_post(%Plug.Conn{method: "POST"}), do: :ok

  def validate_post(_conn) do
    {:error, Error.new(:unimplemented, "Only POST is supported"), 405}
  end

  @doc """
  Validates the required Connect protocol header.
  """
  @spec validate_protocol_version(Plug.Conn.t()) :: :ok | {:error, Error.t(), pos_integer()}
  def validate_protocol_version(conn) do
    case get_req_header(conn, "connect-protocol-version") do
      ["1" | _rest] ->
        :ok

      [] ->
        {:error, Error.new(:invalid_argument, "Missing required Connect-Protocol-Version header"), 400}

      [value | _rest] ->
        {:error, Error.new(:invalid_argument, "Invalid Connect-Protocol-Version header: #{value}"), 400}
    end
  end

  @doc """
  Negotiates the request codec from `Content-Type`.
  """
  @spec negotiate_codec(Plug.Conn.t()) ::
          {:ok, module()} | {:error, Error.t(), pos_integer()}
  def negotiate_codec(conn) do
    content_type = content_type(conn)

    case content_type do
      "application/proto" ->
        {:ok, Proto}

      "application/json" ->
        {:ok, JSON}

      other ->
        {:error, Error.new(:invalid_argument, "Unsupported content type: #{other}"), 415}
    end
  end

  @doc """
  Validates `Content-Encoding` is absent or `identity`.
  """
  @spec validate_compression(Plug.Conn.t()) :: :ok | {:error, Error.t(), pos_integer()}
  def validate_compression(conn) do
    encodings =
      conn
      |> get_req_header("content-encoding")
      |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
      |> Enum.reject(&(&1 == ""))

    case encodings do
      [] ->
        :ok

      ["identity"] ->
        :ok

      _other ->
        {:error, Error.new(:unimplemented, "Compression is not supported"), 501}
    end
  end

  @doc """
  Converts a Connect error code to HTTP status.
  """
  @spec code_to_status(Error.code()) :: pos_integer()
  def code_to_status(code) do
    Map.get(@status_by_code, Error.normalize_code(code), 500)
  end

  @doc """
  Sends a JSON Connect error response.
  """
  @spec send_error(Plug.Conn.t(), Error.t(), pos_integer() | nil) :: Plug.Conn.t()
  def send_error(conn, %Error{} = error, status \\ nil) do
    status = status || code_to_status(error.code)
    body = encode_error(error)

    conn
    |> put_resp_content_type("application", "json")
    |> send_resp(status, body)
  end

  @doc """
  Builds the JSON-serializable map for an error.
  """
  @spec error_payload(Error.t()) :: map()
  def error_payload(%Error{} = error) do
    payload = %{
      "code" => Atom.to_string(Error.normalize_code(error.code)),
      "message" => error.message
    }

    case Enum.map(error.details, &encode_detail/1) do
      [] -> payload
      details -> Map.put(payload, "details", details)
    end
  end

  @doc false
  @spec content_type(Plug.Conn.t()) :: String.t()
  def content_type(conn) do
    case get_req_header(conn, "content-type") do
      [] ->
        "<missing>"

      [header | _rest] ->
        header
        |> String.split(";", parts: 2)
        |> List.first()
        |> String.trim()
        |> String.downcase()
    end
  end

  defp encode_error(error) do
    Jason.encode!(error_payload(error))
  end

  defp encode_detail(%module{} = detail) do
    type = detail_type(module)

    value =
      try do
        detail
        |> module.encode()
        |> Base.encode64()
      rescue
        _exception -> ""
      end

    %{"type" => type, "value" => value}
  end

  defp encode_detail(%{type: type, value: value}) when is_binary(type) and is_binary(value) do
    %{"type" => type, "value" => Base.encode64(value)}
  end

  defp encode_detail(%{"type" => type, "value" => value}) when is_binary(type) and is_binary(value) do
    %{"type" => type, "value" => Base.encode64(value)}
  end

  defp encode_detail(detail) do
    %{
      "type" => "Elixir.Term",
      "value" => detail |> inspect() |> Base.encode64()
    }
  end

  defp detail_type(module) do
    if function_exported?(module, :full_name, 0) do
      case module.full_name() do
        name when is_binary(name) and name != "" ->
          name

        _other ->
          module |> Module.split() |> Enum.join(".")
      end
    else
      module |> Module.split() |> Enum.join(".")
    end
  end
end
