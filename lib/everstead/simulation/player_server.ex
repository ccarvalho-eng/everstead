defmodule EverStead.Simulation.PlayerServer do
  use GenServer
  require Logger

  def start_link({id, name}) do
    GenServer.start_link(__MODULE__, {id, name}, name: via_tuple(id))
  end

  defp via_tuple(id), do: {:via, Registry, {EverStead.PlayerRegistry, id}}

  def init({id, name}) do
    # Minimal player state
    villagers = %{}
    buildings = %{}
    resources = %{wood: 0, stone: 0, food: 0}
    {:ok, %{id: id, name: name, villagers: villagers, buildings: buildings, resources: resources}}
  end

  def handle_info(:tick, state) do
    # Tell JobManager to assign jobs to idle villagers
    EverStead.Simulation.JobManager.assign_jobs(state.villagers)
    {:noreply, state}
  end
end
