defmodule EverStead.Simulation.Player.Server do
  @moduledoc """
  GenServer managing individual player state and game logic.

  Each PlayerServer maintains a player's resources, villagers, and buildings,
  and processes game tick events to update the player's simulation state.

  The server is registered in the PlayerRegistry using the player's ID,
  allowing for dynamic player management and lookup.
  """
  use GenServer
  require Logger

  alias EverStead.Entities.Player
  alias EverStead.Entities.World.Kingdom

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

  @doc """
  Gets the current player state.

  ## Examples

      iex> PlayerServer.get_state("p1")
      %Player{id: "p1", name: "Alice", ...}
  """
  @spec get_state(String.t()) :: Player.t()
  def get_state(player_id) do
    GenServer.call(via_tuple(player_id), :get_state)
  end

  defp via_tuple(id), do: {:via, Registry, {EverStead.PlayerRegistry, id}}

  @impl true
  def init({id, name}) do
    kingdom = %Kingdom{
      id: "kingdom_#{id}",
      name: "#{name}'s Kingdom",
      villagers: [],
      buildings: [],
      resources: [
        %EverStead.Entities.World.Resource{type: :wood, amount: 0},
        %EverStead.Entities.World.Resource{type: :stone, amount: 0},
        %EverStead.Entities.World.Resource{type: :food, amount: 0}
      ]
    }

    player = %Player{
      id: id,
      name: name,
      kingdom: kingdom
    }

    {:ok, player}
  end

  @impl true
  def handle_call(:get_state, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_info(:tick, player) do
    # Tell JobManager to assign jobs to idle villagers
    EverStead.Simulation.Kingdom.JobManager.assign_jobs(player.kingdom.villagers)
    {:noreply, player}
  end
end
