defmodule ConnectRPC.Codec.JSON do
  @moduledoc false

  @type decode_error :: Exception.t() | term()
  @type encode_error :: Exception.t() | term()

  @spec id() :: :json
  def id, do: :json

  @spec media_type() :: String.t()
  def media_type, do: "application/json"

  @spec decode(binary(), module()) :: {:ok, struct()} | {:error, decode_error()}
  def decode(payload, module) when is_binary(payload) and is_atom(module) do
    Protobuf.JSON.decode(payload, module)
  rescue
    exception -> {:error, exception}
  end

  @spec encode(struct()) :: {:ok, binary()} | {:error, encode_error()}
  def encode(%_{} = struct) do
    Protobuf.JSON.encode(struct)
  rescue
    exception -> {:error, exception}
  end
end
