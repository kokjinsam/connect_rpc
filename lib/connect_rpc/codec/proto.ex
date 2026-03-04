defmodule ConnectRPC.Codec.Proto do
  @moduledoc """
  Protocol Buffers binary codec for ConnectRPC using `application/proto` content type.
  """

  @behaviour ConnectRPC.Codec

  @type decode_error :: Exception.t() | term()
  @type encode_error :: Exception.t() | term()

  @spec media_type() :: String.t()
  def media_type, do: "application/proto"

  @spec decode(binary(), module()) :: {:ok, struct()} | {:error, decode_error()}
  def decode(payload, module) when is_binary(payload) and is_atom(module) do
    {:ok, module.decode(payload)}
  rescue
    exception -> {:error, exception}
  end

  @spec encode(struct()) :: {:ok, binary()} | {:error, encode_error()}
  def encode(%module{} = struct) when is_atom(module) do
    {:ok, module.encode(struct)}
  rescue
    exception -> {:error, exception}
  end
end
