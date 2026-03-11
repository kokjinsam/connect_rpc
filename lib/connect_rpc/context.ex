defmodule ConnectRPC.Context do
  @moduledoc """
  Per-request context passed to handler callbacks.
  """

  @type t :: %__MODULE__{assigns: %{optional(atom()) => term()}}
  defstruct assigns: %{}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec assign(t(), atom(), term()) :: t()
  def assign(%__MODULE__{} = context, key, value) when is_atom(key) do
    %{context | assigns: Map.put(context.assigns, key, value)}
  end

  @spec get(t(), atom(), term()) :: term()
  def get(%__MODULE__{} = context, key, default \\ nil) when is_atom(key) do
    Map.get(context.assigns, key, default)
  end

  @spec put(Plug.Conn.t(), atom(), term()) :: Plug.Conn.t()
  def put(%Plug.Conn{} = conn, key, value) when is_atom(key) do
    context =
      case conn.private[:connect_rpc_context] do
        %__MODULE__{} = existing_context -> existing_context
        _ -> new()
      end

    Plug.Conn.put_private(conn, :connect_rpc_context, assign(context, key, value))
  end
end
