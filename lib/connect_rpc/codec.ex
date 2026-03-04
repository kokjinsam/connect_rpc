defmodule ConnectRPC.Codec do
  @moduledoc """
  Behaviour for ConnectRPC request/response codecs.
  """

  @callback media_type() :: String.t()
  @callback encode(struct()) :: {:ok, iodata()} | {:error, term()}
  @callback decode(binary(), module()) :: {:ok, struct()} | {:error, term()}
end
