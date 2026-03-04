defmodule ConnectRPC.Codec.JSON do
  @moduledoc """
  JSON codec for ConnectRPC using `application/json` content type.

  Delegates to `Protobuf.JSON` for encoding and decoding.
  """

  @behaviour ConnectRPC.Codec

  @type decode_error :: Exception.t() | term()
  @type encode_error :: Exception.t() | term()

  @spec media_type() :: String.t()
  def media_type, do: "application/json"

  @spec decode(binary(), module()) :: {:ok, struct()} | {:error, decode_error()}
  def decode(payload, module) when is_binary(payload) and is_atom(module) do
    Protobuf.JSON.decode(payload, module)
  rescue
    exception -> {:error, exception}
  end

  @spec encode(struct()) :: {:ok, binary()} | {:error, encode_error()}
  def encode(%module{} = struct) when is_atom(module) do
    Protobuf.JSON.encode(struct)
  rescue
    exception -> {:error, exception}
  end
end
