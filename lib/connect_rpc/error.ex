defmodule ConnectRPC.Error do
  @moduledoc """
  Connect protocol error structure.
  """

  @type code ::
          :canceled
          | :unknown
          | :invalid_argument
          | :deadline_exceeded
          | :not_found
          | :already_exists
          | :permission_denied
          | :resource_exhausted
          | :failed_precondition
          | :aborted
          | :out_of_range
          | :unimplemented
          | :internal
          | :unavailable
          | :data_loss
          | :unauthenticated

  @codes ~w(
    canceled
    unknown
    invalid_argument
    deadline_exceeded
    not_found
    already_exists
    permission_denied
    resource_exhausted
    failed_precondition
    aborted
    out_of_range
    unimplemented
    internal
    unavailable
    data_loss
    unauthenticated
  )a

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          details: [term()]
        }

  defexception code: :unknown, message: "", details: []

  @doc """
  Creates a new `ConnectRPC.Error`.
  """
  @spec new(code(), String.t(), [term()]) :: t()
  def new(code, message, details \\ []) do
    %__MODULE__{
      code: normalize_code(code),
      message: to_string(message),
      details: normalize_details(details)
    }
  end

  @doc """
  Returns true when `code` is a valid Connect error code atom.
  """
  @spec valid_code?(atom()) :: boolean()
  def valid_code?(code) when is_atom(code), do: code in @codes
  def valid_code?(_code), do: false

  @doc false
  @spec normalize_code(atom()) :: code()
  def normalize_code(code) when code in @codes, do: code
  def normalize_code(_code), do: :unknown

  defp normalize_details(details) when is_list(details), do: details
  defp normalize_details(detail), do: [detail]
end
