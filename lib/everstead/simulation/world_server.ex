defmodule EverStead.Simulation.WorldServer do
  use GenServer

  require Logger

  @tick_interval 1_000

  # Client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server callbacks
  def init(state) do
    schedule_tick()
    {:ok, state}
  end

  def handle_info(:tick, state) do
    Logger.info("World tick fired")
    # Broadcast tickt to all PlayerServers
    EverStead.Simulation.PlayerSupervisor.broadcast_tick()
    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end
end
