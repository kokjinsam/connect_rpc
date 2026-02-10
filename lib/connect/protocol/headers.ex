defmodule Connect.Protocol.Headers do
  @moduledoc """
  ConnectRPC header utilities: reserved header filtering,
  binary header (`-Bin` suffix) encoding/decoding, and
  protocol header detection.
  """

  # Protocol-reserved headers that must not be forwarded as application metadata.
  # Matches connect-go header.go:23-46.
  @reserved_headers MapSet.new([
                      "content-type",
                      "content-length",
                      "content-encoding",
                      "accept-encoding",
                      "host",
                      "user-agent",
                      "trailer",
                      "te",
                      "date",
                      "connect-protocol-version",
                      "connect-timeout-ms",
                      "connect-content-encoding",
                      "connect-accept-encoding"
                    ])

  @doc """
  Returns true if the header name is a Connect-reserved protocol header
  that should not be treated as application metadata.

  Any header starting with `"connect-"` is considered reserved.
  """
  @spec reserved?(String.t()) :: boolean()
  def reserved?(name) when is_binary(name) do
    lower = String.downcase(name)
    MapSet.member?(@reserved_headers, lower) or String.starts_with?(lower, "connect-")
  end

  @doc """
  Filters a list of `{name, value}` header pairs, removing all
  reserved protocol headers. Returns only application metadata headers.
  """
  @spec filter_reserved([{String.t(), String.t()}]) :: [{String.t(), String.t()}]
  def filter_reserved(headers) when is_list(headers) do
    Enum.reject(headers, fn {name, _value} -> reserved?(name) end)
  end

  @doc """
  Encodes a binary value for a `-Bin` suffixed header using
  standard base64, unpadded (matching connect-go / gRPC convention).
  """
  @spec encode_binary_header(binary()) :: String.t()
  def encode_binary_header(value) when is_binary(value) do
    Base.encode64(value, padding: false)
  end

  @doc """
  Decodes a base64-encoded `-Bin` header value back to raw binary.
  Handles both padded and unpadded input.

  Returns `{:ok, binary}` or `{:error, :invalid_base64}`.
  """
  @spec decode_binary_header(String.t()) :: {:ok, binary()} | {:error, :invalid_base64}
  def decode_binary_header(encoded) when is_binary(encoded) do
    # If length is not a multiple of 4, it's definitely unpadded.
    # Otherwise it may be padded or padding wasn't needed — try padded first.
    case rem(byte_size(encoded), 4) do
      0 ->
        case Base.decode64(encoded) do
          {:ok, _} = result -> result
          :error -> {:error, :invalid_base64}
        end

      _ ->
        case Base.decode64(encoded, padding: false) do
          {:ok, _} = result -> result
          :error -> {:error, :invalid_base64}
        end
    end
  end

  @doc """
  Returns true if the header name ends with `-bin` (case-insensitive),
  indicating it carries base64-encoded binary data.
  """
  @spec binary_header?(String.t()) :: boolean()
  def binary_header?(name) when is_binary(name) do
    name |> String.downcase() |> String.ends_with?("-bin")
  end
end
