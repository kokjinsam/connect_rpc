defmodule Connect.Error do
  @moduledoc """
  ConnectRPC error representation with canonical code validation,
  wire format serialization, and HTTP status mapping.

  ## Wire Format

  Errors are serialized as JSON on the wire:

      {"code": "not_found", "message": "User not found", "details": [...]}

  Details follow the Connect wire format:

      {"type": "type.googleapis.com/...", "value": "<base64>", "debug": {...}}
  """

  @valid_codes ~w(
    canceled unknown invalid_argument deadline_exceeded not_found
    already_exists permission_denied resource_exhausted failed_precondition
    aborted out_of_range unimplemented internal unavailable data_loss
    unauthenticated
  )

  # Exact mapping per connect-go protocol_connect.go:1269-1308
  @code_to_status %{
    "canceled" => 499,
    "unknown" => 500,
    "invalid_argument" => 400,
    "deadline_exceeded" => 504,
    "not_found" => 404,
    "already_exists" => 409,
    "permission_denied" => 403,
    "resource_exhausted" => 429,
    "failed_precondition" => 400,
    "aborted" => 409,
    "out_of_range" => 400,
    "unimplemented" => 501,
    "internal" => 500,
    "unavailable" => 503,
    "data_loss" => 500,
    "unauthenticated" => 401
  }

  defstruct [:code, :message, details: [], metadata: %{}]

  @type t :: %__MODULE__{
          code: String.t(),
          message: String.t() | nil,
          details: [detail()],
          metadata: %{String.t() => String.t()}
        }

  @type detail :: %{
          type: String.t(),
          value: binary(),
          debug: map() | nil
        }

  @doc "Returns the list of valid Connect error code strings."
  @spec valid_codes() :: [String.t()]
  def valid_codes, do: @valid_codes

  @doc "Returns true if the given string is a valid Connect error code."
  @spec valid_code?(String.t()) :: boolean()
  def valid_code?(code) when is_binary(code), do: code in @valid_codes

  @doc """
  Creates a new Connect error.

  Raises `ArgumentError` if the code is not a valid Connect error code.

  ## Options

    * `:details` - list of detail maps (default: `[]`)
    * `:metadata` - map of metadata key/value pairs (default: `%{}`)
  """
  @spec new(String.t(), String.t() | nil, keyword()) :: t()
  def new(code, message \\ nil, opts \\ [])

  for code <- @valid_codes do
    def new(unquote(code), message, opts) do
      %__MODULE__{
        code: unquote(code),
        message: message,
        details: Keyword.get(opts, :details, []),
        metadata: Keyword.get(opts, :metadata, %{})
      }
    end
  end

  def new(code, _message, _opts) do
    raise ArgumentError, "invalid Connect error code: #{inspect(code)}"
  end

  @doc "Returns the HTTP status code for a Connect error code."
  @spec code_to_http_status(String.t()) :: pos_integer()
  def code_to_http_status(code), do: Map.get(@code_to_status, code, 500)

  @doc """
  Serializes the error to the Connect wire JSON format.
  Always produces JSON regardless of the request codec.
  """
  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = error) do
    Jason.encode!(to_wire_map(error))
  end

  @doc """
  Converts the error to the wire map representation.
  Omits keys with nil/empty values per Connect spec convention.
  """
  @spec to_wire_map(t()) :: map()
  def to_wire_map(%__MODULE__{} = error) do
    map = %{"code" => error.code}
    map = if error.message, do: Map.put(map, "message", error.message), else: map

    if error.details != [],
      do: Map.put(map, "details", encode_details(error.details)),
      else: map
  end

  @doc """
  Parses a wire-format JSON map into a `Connect.Error` struct.

  Returns `{:ok, error}` or `{:error, reason}`.
  """
  @spec from_wire_map(map()) :: {:ok, t()} | {:error, atom()}
  def from_wire_map(%{"code" => code} = map) when is_binary(code) do
    if valid_code?(code) do
      {:ok,
       %__MODULE__{
         code: code,
         message: Map.get(map, "message"),
         details: decode_details(Map.get(map, "details", [])),
         metadata: %{}
       }}
    else
      {:error, :invalid_error_code}
    end
  end

  def from_wire_map(_), do: {:error, :invalid_error_format}

  @doc """
  Sends a ConnectRPC error as a unary HTTP response.
  Always uses `application/json` content type regardless of request codec.
  """
  @spec send_unary(Plug.Conn.t(), t()) :: Plug.Conn.t()
  def send_unary(conn, %__MODULE__{} = error) do
    status = code_to_http_status(error.code)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, to_json(error))
  end

  @doc """
  Formats an error for a streaming EndStream frame.
  Includes metadata when present.
  """
  @spec to_end_stream(t()) :: map()
  def to_end_stream(%__MODULE__{} = error) do
    end_stream = %{"error" => to_wire_map(error)}

    if error.metadata != %{} do
      Map.put(end_stream, "metadata", encode_metadata(error.metadata))
    else
      end_stream
    end
  end

  # --- Private helpers ---

  defp encode_details(details) do
    Enum.map(details, fn %{type: type, value: value} = detail ->
      encoded = %{"type" => type, "value" => Base.encode64(value)}

      case Map.get(detail, :debug) do
        nil -> encoded
        debug -> Map.put(encoded, "debug", debug)
      end
    end)
  end

  defp decode_details(details) when is_list(details) do
    details
    |> Enum.map(fn
      %{"type" => type, "value" => value_b64} = detail ->
        case Base.decode64(value_b64) do
          {:ok, value} -> %{type: type, value: value, debug: Map.get(detail, "debug")}
          :error -> %{type: type, value: "", debug: Map.get(detail, "debug")}
        end

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp decode_details(_), do: []

  defp encode_metadata(metadata) when is_map(metadata) do
    Enum.into(metadata, %{}, fn {k, v} ->
      if Connect.Protocol.Headers.binary_header?(k) do
        {k, [Base.encode64(v)]}
      else
        {k, [v]}
      end
    end)
  end
end
