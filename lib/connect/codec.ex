defmodule Connect.Codec do
  @moduledoc """
  Serialization dispatch for JSON and Protobuf binary formats.
  """

  @doc """
  Decodes binary data into the given protobuf module's struct.

  Returns `{:ok, struct}` or `{:error, exception}`.
  """
  @spec decode(binary(), module(), :json | :binary) :: {:ok, struct()} | {:error, Exception.t()}
  def decode(data, type, :binary) do
    {:ok, type.decode(data)}
  rescue
    e -> {:error, e}
  end

  def decode(data, type, :json) do
    {:ok, Protobuf.JSON.decode!(data, type)}
  rescue
    e -> {:error, e}
  end

  @doc """
  Encodes a protobuf struct into the given format.
  """
  @spec encode(struct(), :json | :binary) :: binary()
  def encode(struct, :binary), do: Protobuf.encode(struct)
  def encode(struct, :json), do: Protobuf.JSON.encode!(struct)
end
