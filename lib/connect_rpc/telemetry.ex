defmodule ConnectRPC.Telemetry do
  @moduledoc false

  @start_event [:connect_rpc, :handler, :start]
  @stop_event [:connect_rpc, :handler, :stop]
  @exception_event [:connect_rpc, :handler, :exception]

  @spec emit_handler_start(map()) :: :ok
  def emit_handler_start(metadata) do
    :telemetry.execute(@start_event, %{system_time: System.system_time()}, metadata)
  end

  @spec emit_handler_stop(integer(), map()) :: :ok
  def emit_handler_stop(start_time, metadata) do
    duration = System.monotonic_time() - start_time
    :telemetry.execute(@stop_event, %{duration: duration}, metadata)
  end

  @spec emit_handler_exception(integer(), map(), :error | :throw | :exit, term(), list()) :: :ok
  def emit_handler_exception(start_time, metadata, kind, reason, stacktrace) do
    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      @exception_event,
      %{duration: duration},
      Map.merge(metadata, %{kind: kind, reason: reason, stacktrace: stacktrace})
    )
  end
end
