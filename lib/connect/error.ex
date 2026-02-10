defmodule Connect.Error do
  @moduledoc """
  ConnectRPC error representation and response helpers.
  """

  @derive Jason.Encoder
  defstruct [:code, :message, details: []]

  @type t :: %__MODULE__{
          code: String.t(),
          message: String.t(),
          details: list()
        }

  @code_to_status %{
    "canceled" => 408,
    "unknown" => 500,
    "invalid_argument" => 400,
    "deadline_exceeded" => 408,
    "not_found" => 404,
    "already_exists" => 409,
    "permission_denied" => 403,
    "resource_exhausted" => 429,
    "failed_precondition" => 412,
    "aborted" => 409,
    "out_of_range" => 400,
    "unimplemented" => 404,
    "internal" => 500,
    "unavailable" => 503,
    "data_loss" => 500,
    "unauthenticated" => 401
  }

  @spec new(String.t(), String.t()) :: t()
  def new(code, message), do: %__MODULE__{code: code, message: message}

  @doc "Returns the HTTP status code for a Connect error code."
  @spec code_to_http_status(String.t()) :: pos_integer()
  def code_to_http_status(code), do: Map.get(@code_to_status, code, 500)

  @doc "Sends a ConnectRPC error as a unary HTTP response."
  @spec send_unary(Plug.Conn.t(), t()) :: Plug.Conn.t()
  def send_unary(conn, %__MODULE__{} = error) do
    status = code_to_http_status(error.code)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, Jason.encode!(error))
  end

  @doc "Formats an error for a streaming EndStream frame."
  @spec to_end_stream(t()) :: map()
  def to_end_stream(%__MODULE__{} = error) do
    %{"error" => %{"code" => error.code, "message" => error.message}}
  end
end
