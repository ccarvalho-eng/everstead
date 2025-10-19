defmodule Everstead.Simulation.Player.Server do
  @moduledoc """
  GenServer managing individual player state and game logic.

  Each PlayerServer maintains a player's resources, villagers, and buildings,
  and processes game tick events to update the player's simulation state.

  The server is registered in the PlayerRegistry using the player's ID,
  allowing for dynamic player management and lookup.
  """
  use GenServer
  require Logger

  alias Everstead.Entities.Player
  alias Everstead.Entities.World.Kingdom

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

  @doc """
  Gets all villagers for this player from the villager registry.

  ## Parameters
  - `player_id` - The ID of the player

  ## Returns
  - `%{String.t() => Villager.t()}` - Map of villager IDs to villager states

  ## Examples

      iex> PlayerServer.get_villagers("p1")
      %{"v1" => %Villager{id: "v1", name: "Bob", state: :idle}}
  """
  @spec get_villagers(String.t()) :: %{
          String.t() => Everstead.Entities.World.Kingdom.Villager.t()
        }
  def get_villagers(player_id) do
    GenServer.call(via_tuple(player_id), :get_villagers)
  end

  @doc """
  Adds a villager to the player's kingdom state.

  This adds a villager entity to the kingdom.villagers list.

  ## Parameters
  - `player_id` - The ID of the player
  - `villager` - The villager entity to add

  ## Examples

      iex> PlayerServer.add_villager("p1", %Villager{id: "v1", name: "Bob"})
      :ok
  """
  @spec add_villager(String.t(), Everstead.Entities.World.Kingdom.Villager.t()) :: :ok
  def add_villager(player_id, villager) do
    GenServer.cast(via_tuple(player_id), {:add_villager, villager})
  end

  @doc """
  Syncs the player's kingdom state with the current villager server states.

  This updates the kingdom.villagers list to match the current state of
  all villager server processes belonging to this player.

  ## Parameters
  - `player_id` - The ID of the player to sync

  ## Examples

      iex> PlayerServer.sync_kingdom_villagers("p1")
      :ok
  """
  @spec sync_kingdom_villagers(String.t()) :: :ok
  def sync_kingdom_villagers(player_id) do
    GenServer.cast(via_tuple(player_id), :sync_kingdom_villagers)
  end

  defp via_tuple(id), do: {:via, Registry, {Everstead.PlayerRegistry, id}}

  @impl true
  def init({id, name}) do
    kingdom = %Kingdom{
      id: "kingdom_#{id}",
      name: "#{name}'s Kingdom",
      villagers: [],
      buildings: [],
      resources: [
        %Everstead.Entities.World.Resource{type: :wood, amount: 0},
        %Everstead.Entities.World.Resource{type: :stone, amount: 0},
        %Everstead.Entities.World.Resource{type: :food, amount: 0}
      ]
    }

    player = %Player{
      id: id,
      name: name,
      kingdom: kingdom
    }

    Logger.info("Player server started for #{name} (#{id})")
    {:ok, player}
  end

  @impl true
  def handle_call(:get_state, _from, player) do
    {:reply, player, player}
  end

  @impl true
  def handle_call(:get_villagers, _from, player) do
    try do
      # Get all villager processes for this player from the registry
      villager_map =
        Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
        |> Enum.reduce(%{}, fn villager_id, acc ->
          try do
            full_state = Everstead.Simulation.Kingdom.Villager.Server.get_full_state(villager_id)
            # Only include villagers that belong to this player
            if full_state.player_id == player.id do
              Map.put(acc, villager_id, full_state.villager)
            else
              acc
            end
          catch
            :exit, reason ->
              Logger.warning(
                "Villager #{villager_id} exited during get_villagers: #{inspect(reason)}"
              )

              acc

            error ->
              Logger.error("Error getting villager #{villager_id} state: #{inspect(error)}")
              acc
          end
        end)

      {:reply, villager_map, player}
    catch
      error ->
        Logger.error("Error in get_villagers for player #{player.id}: #{inspect(error)}")
        {:reply, %{}, player}
    end
  end

  @impl true
  def handle_cast({:add_villager, villager}, player) do
    # Add the villager to the kingdom's villager list
    updated_villagers = [villager | player.kingdom.villagers]
    updated_kingdom = %{player.kingdom | villagers: updated_villagers}
    updated_player = %{player | kingdom: updated_kingdom}

    {:noreply, updated_player}
  end

  @impl true
  def handle_cast(:sync_kingdom_villagers, player) do
    # Get all villager processes for this player and update the kingdom state
    villager_list =
      Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
      |> Enum.reduce([], fn villager_id, acc ->
        try do
          full_state = Everstead.Simulation.Kingdom.Villager.Server.get_full_state(villager_id)
          # Only include villagers that belong to this player
          if full_state.player_id == player.id do
            [full_state.villager | acc]
          else
            acc
          end
        catch
          :exit, _ -> acc
        end
      end)

    # Update the kingdom with the current villager list
    updated_kingdom = %{player.kingdom | villagers: villager_list}
    updated_player = %{player | kingdom: updated_kingdom}

    {:noreply, updated_player}
  end

  @impl true
  def handle_info(:tick, player) do
    try do
      # Get all villager processes for this player and create a map for job assignment
      villager_map =
        Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
        |> Enum.reduce(%{}, fn villager_id, acc ->
          try do
            full_state = Everstead.Simulation.Kingdom.Villager.Server.get_full_state(villager_id)
            # Only include villagers that belong to this player
            if full_state.player_id == player.id do
              Map.put(acc, villager_id, full_state.villager)
            else
              acc
            end
          catch
            :exit, reason ->
              Logger.warning("Villager #{villager_id} exited during tick: #{inspect(reason)}")
              acc

            error ->
              Logger.error(
                "Error getting villager #{villager_id} state during tick: #{inspect(error)}"
              )

              acc
          end
        end)

      # Tell JobManager to assign jobs to idle villagers
      try do
        job_manager_name =
          {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_#{player.id}"}}

        Everstead.Simulation.Kingdom.JobManager.Server.assign_jobs(job_manager_name, villager_map)
      catch
        error ->
          Logger.error("Error assigning jobs to villagers: #{inspect(error)}")
      end

      {:noreply, player}
    catch
      error ->
        Logger.error("Error in player tick for #{player.id}: #{inspect(error)}")
        {:noreply, player}
    end
  end
end
