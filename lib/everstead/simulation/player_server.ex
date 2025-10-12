defmodule EverStead.Simulation.PlayerServer do
  @moduledoc """
  GenServer managing individual player state and game logic.

  Each PlayerServer maintains a player's resources, villagers, and buildings,
  and processes game tick events to update the player's simulation state.

  The server is registered in the PlayerRegistry using the player's ID,
  allowing for dynamic player management and lookup.
  """
  use GenServer
  require Logger

  @doc """
  Starts a player server process.

  ## Parameters
  - `{id, name}` - Tuple containing the player ID and display name

  The server is registered via the PlayerRegistry using the player ID.
  """
  @spec start_link({String.t(), String.t()}) :: GenServer.on_start()
  def start_link({id, name}) do
    GenServer.start_link(__MODULE__, {id, name}, name: via_tuple(id))
  end

  defp via_tuple(id), do: {:via, Registry, {EverStead.PlayerRegistry, id}}

  @impl true
  def init({id, name}) do
    # Minimal player state
    villagers = %{}
    buildings = %{}
    resources = %{wood: 0, stone: 0, food: 0}
    {:ok, %{id: id, name: name, villagers: villagers, buildings: buildings, resources: resources}}
  end

  @impl true
  def handle_info(:tick, state) do
    # Tell JobManager to assign jobs to idle villagers
    EverStead.Simulation.JobManager.assign_jobs(state.villagers)
    {:noreply, state}
  end
end
