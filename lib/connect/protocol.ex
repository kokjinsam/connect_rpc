defmodule Connect.Protocol do
  @moduledoc """
  Content-type parsing, wire mode classification, and protocol
  validation for the Connect protocol.
  """

  @type codec :: :json | :binary
  @type wire_mode :: :unary | :streaming

  @doc """
  Parses the `content-type` header and returns the wire mode and codec.

  For unary content types (`application/json`, `application/proto`), charset
  parameters are stripped before matching (lenient).

  For streaming content types (`application/connect+json`, `application/connect+proto`),
  any parameters cause rejection — the Connect spec requires exact content-type
  matching for streaming.

  Returns `{:ok, %{wire_mode: wire_mode, codec: codec}}` or
  `{:error, :unsupported_media_type}`.
  """
  @spec parse_content_type(Plug.Conn.t()) ::
          {:ok, %{wire_mode: wire_mode(), codec: codec()}} | {:error, :unsupported_media_type}
  def parse_content_type(conn) do
    raw =
      conn
      |> Plug.Conn.get_req_header("content-type")
      |> List.first("")
      |> String.trim()

    # Try exact match first (handles streaming types strictly)
    case classify_exact(raw) do
      {:ok, _} = result ->
        result

      :no_match ->
        # Strip parameters and try unary-only classification
        base = raw |> String.split(";") |> hd() |> String.trim()
        classify_unary_only(base)
    end
  end

  # Exact match — streaming types must match exactly (no params).
  # Unary types also match here for the common no-params case.
  defp classify_exact("application/json"), do: {:ok, %{wire_mode: :unary, codec: :json}}
  defp classify_exact("application/proto"), do: {:ok, %{wire_mode: :unary, codec: :binary}}

  defp classify_exact("application/connect+json"),
    do: {:ok, %{wire_mode: :streaming, codec: :json}}

  defp classify_exact("application/connect+proto"),
    do: {:ok, %{wire_mode: :streaming, codec: :binary}}

  defp classify_exact(_), do: :no_match

  # After stripping params, only unary types are accepted.
  # If someone sent "application/connect+json; charset=utf-8", the exact match
  # failed and this won't match either — correctly rejected.
  defp classify_unary_only("application/json"), do: {:ok, %{wire_mode: :unary, codec: :json}}
  defp classify_unary_only("application/proto"), do: {:ok, %{wire_mode: :unary, codec: :binary}}
  defp classify_unary_only(_), do: {:error, :unsupported_media_type}

  @doc """
  Validates that the request uses HTTP POST.

  Returns `:ok` or `{:error, :method_not_allowed}`.
  """
  @spec validate_method(Plug.Conn.t()) :: :ok | {:error, :method_not_allowed}
  def validate_method(%Plug.Conn{method: "POST"}), do: :ok
  def validate_method(%Plug.Conn{}), do: {:error, :method_not_allowed}

  @doc """
  Validates the `Connect-Protocol-Version` header.

  Options:
    * `:required` - when `true` (default), a missing header is rejected.
      When `false`, a missing header is accepted (for backward compat).

  Returns `:ok` or `{:error, :unsupported_protocol_version}`.
  """
  @spec validate_protocol_version(Plug.Conn.t(), keyword()) ::
          :ok | {:error, :unsupported_protocol_version}
  def validate_protocol_version(conn, opts \\ []) do
    required = Keyword.get(opts, :required, true)

    case Plug.Conn.get_req_header(conn, "connect-protocol-version") do
      ["1"] -> :ok
      [] when required -> {:error, :unsupported_protocol_version}
      [] -> :ok
      _other -> {:error, :unsupported_protocol_version}
    end
  end

  @doc "Returns the MIME type for unary responses."
  @spec mime_type(codec()) :: String.t()
  def mime_type(:json), do: "application/json"
  def mime_type(:binary), do: "application/proto"

  @doc "Returns the MIME type for streaming responses."
  @spec stream_mime_type(codec()) :: String.t()
  def stream_mime_type(:json), do: "application/connect+json"
  def stream_mime_type(:binary), do: "application/connect+proto"
end
