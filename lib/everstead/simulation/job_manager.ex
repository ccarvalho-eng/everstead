defmodule EverStead.Simulation.JobManager do
  use GenServer
  require Logger

  # Client
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Server
  def init(state), do: {:ok, state}

  def assign_jobs(villagers) do
    GenServer.cast(__MODULE__, {:assign_jobs, villagers})
  end

  def handle_cast({:assign_jobs, villagers}, state) do
    Enum.each(villagers, fn {id, villager} ->
      if villager.state == :idle do
        Logger.info("Assigning gather wood job to villager #{id}")
        # In a real system, send job to VillagerServer
      end
    end)

    {:noreply, state}
  end
end
