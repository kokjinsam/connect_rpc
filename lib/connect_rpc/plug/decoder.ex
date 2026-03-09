defmodule ConnectRPC.Plug.Decoder do
  @moduledoc false

  @behaviour Plug

  alias ConnectRPC.Error
  alias ConnectRPC.Protocol

  @body_consumed_error_message "Request body already consumed by an upstream parser. Exclude ConnectRPC paths from Plug.Parsers using the :pass option."

  @impl Plug
  def init(opts) do
    %{
      read_body_opts: Keyword.get(opts, :read_body_opts, []),
      read_body_fun: Keyword.get(opts, :read_body_fun, &Plug.Conn.read_body/2)
    }
  end

  @impl Plug
  def call(conn, %{read_body_opts: read_body_opts, read_body_fun: read_body_fun}) do
    rpc_meta = conn.private.connect_rpc_rpc

    codec =
      conn.assigns[:connect_rpc_codec] ||
        raise RuntimeError,
              "No codec assigned. Ensure ConnectRPC.Plug.Codec runs before ConnectRPC.Plug.Decoder."

    with :ok <- validate_body_parser_ownership(conn),
         {:ok, body, conn} <- read_full_body(conn, read_body_fun, read_body_opts),
         {:ok, request_struct} <- decode_request(codec, body, rpc_meta.request, conn) do
      Plug.Conn.assign(conn, :connect_rpc_request, request_struct)
    else
      {:error, :body_already_consumed} ->
        raise RuntimeError, @body_consumed_error_message

      {:error, {:read_body, reason}, conn} ->
        conn
        |> map_body_read_error(reason)
        |> Plug.Conn.halt()

      {:error, {:decode, _reason}, conn} ->
        conn
        |> Protocol.send_error(Error.new(:invalid_argument, "Invalid request body"), 400)
        |> Plug.Conn.halt()
    end
  end

  defp decode_request(codec, body, request_module, conn) do
    case codec.decode(body, request_module) do
      {:ok, request} -> {:ok, request}
      {:error, reason} -> {:error, {:decode, reason}, conn}
    end
  end

  defp read_full_body(conn, read_body_fun, read_body_opts) do
    do_read_full_body(conn, read_body_fun, read_body_opts, [])
  end

  defp do_read_full_body(conn, read_body_fun, read_body_opts, acc) do
    case read_body_fun.(conn, read_body_opts) do
      {:ok, chunk, conn} ->
        body = [chunk | acc] |> Enum.reverse() |> IO.iodata_to_binary()
        {:ok, body, conn}

      {:more, chunk, conn} ->
        do_read_full_body(conn, read_body_fun, read_body_opts, [chunk | acc])

      {:error, reason} ->
        {:error, {:read_body, reason}, conn}

      {:error, reason, conn} ->
        {:error, {:read_body, reason}, conn}
    end
  end

  defp map_body_read_error(conn, :too_large) do
    Protocol.send_error(conn, Error.new(:resource_exhausted, "Request body too large"), 413)
  end

  defp map_body_read_error(conn, :timeout) do
    Protocol.send_error(conn, Error.new(:deadline_exceeded, "Request body read timed out"), 504)
  end

  defp map_body_read_error(conn, _reason) do
    Protocol.send_error(conn, Error.new(:internal, "Failed to read request body"), 500)
  end

  defp validate_body_parser_ownership(%Plug.Conn{body_params: %Plug.Conn.Unfetched{}}), do: :ok
  defp validate_body_parser_ownership(_conn), do: {:error, :body_already_consumed}
end
