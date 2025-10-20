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
  - `{id, name, kingdom_name}` - Tuple containing the player ID, display name, and kingdom name

  The server is registered via the PlayerRegistry using the player ID.
  """
  @spec start_link({String.t(), String.t(), String.t()}) :: GenServer.on_start()
  def start_link({id, name, kingdom_name}) do
    GenServer.start_link(__MODULE__, {id, name, kingdom_name}, name: via_tuple(id))
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
  def init({id, name, kingdom_name}) do
    # Create 5 default villagers
    default_villagers = create_default_villagers(id)

    # Create some default buildings
    default_buildings = create_default_buildings(id)

    kingdom = %Kingdom{
      id: "kingdom_#{id}",
      name: kingdom_name,
      villagers: default_villagers,
      buildings: default_buildings,
      resources: [
        %Everstead.Entities.World.Resource{type: :wood, amount: 500},
        %Everstead.Entities.World.Resource{type: :stone, amount: 300},
        %Everstead.Entities.World.Resource{type: :food, amount: 1000}
      ]
    }

    player = %Player{
      id: id,
      name: name,
      kingdom: kingdom
    }

    Logger.info(
      "Player server started for #{name} (#{id}) with kingdom '#{kingdom_name}' - #{length(default_villagers)} villagers and #{length(default_buildings)} buildings"
    )

    # Start villager server processes after a short delay to ensure kingdom supervisor is ready
    Process.send_after(self(), :start_villager_servers, 100)

    {:ok, player}
  end

  defp create_default_villagers(player_id) do
    # Medieval/mystical name pools
    medieval_names = [
      "Thorin",
      "Eldara",
      "Gareth",
      "Aria",
      "Finnian",
      "Lysander",
      "Seraphina",
      "Caspian",
      "Isolde",
      "Benedict",
      "Celeste",
      "Orion",
      "Luna",
      "Percival",
      "Aurelia",
      "Magnus",
      "Ophelia",
      "Cedric",
      "Vivienne",
      "Tristan",
      "Elara",
      "Dorian",
      "Cassandra",
      "Leander",
      "Aurora",
      "Valentine",
      "Lilith",
      "Phoenix",
      "Evangeline",
      "Atticus",
      "Persephone",
      "Lucian",
      "Cordelia",
      "Maximus",
      "Beatrice",
      "Sebastian",
      "Ophelia",
      "Damien",
      "Seraphina",
      "Alexander",
      "Guinevere",
      "Raphael",
      "Isabella",
      "Gabriel",
      "Violet",
      "Nathaniel"
    ]

    # 2 builders, 2 farmers, 1 miner
    professions = [:builder, :farmer, :miner, :builder, :farmer]

    # Randomly select 5 unique names
    selected_names = medieval_names |> Enum.shuffle() |> Enum.take(5)

    villager_data =
      selected_names
      |> Enum.with_index(1)
      |> Enum.zip(professions)
      |> Enum.map(fn {{name, index}, profession} ->
        {"v#{index}", name, profession}
      end)

    Enum.map(villager_data, fn {villager_id, villager_name, profession} ->
      %Everstead.Entities.World.Kingdom.Villager{
        id: "#{player_id}_#{villager_id}",
        name: villager_name,
        state: :idle,
        profession: profession,
        location: %{x: 0, y: 0},
        inventory: %{}
      }
    end)
  end

  defp create_default_buildings(player_id) do
    building_data = [
      # Main house - fully built
      {"b1", :house, {5, 5}, 100},
      # Second house - fully built
      {"b2", :house, {8, 5}, 100},
      # Farm - fully built
      {"b3", :farm, {2, 2}, 100},
      # Lumberyard - fully built
      {"b4", :lumberyard, {10, 10}, 100},
      # Storage - fully built
      {"b5", :storage, {12, 8}, 100},
      # House under construction
      {"b6", :house, {15, 3}, 75},
      # Farm under construction
      {"b7", :farm, {3, 8}, 50}
    ]

    Enum.map(building_data, fn {building_id, building_type, location, progress} ->
      %Everstead.Entities.World.Kingdom.Building{
        id: "#{player_id}_#{building_id}",
        type: building_type,
        location: location,
        construction_progress: progress,
        hp: 100
      }
    end)
  end

  defp start_villager_servers(villagers, player_id) do
    case Registry.lookup(Everstead.KingdomRegistry, "villagers_#{player_id}") do
      [] ->
        Logger.warning("Villager supervisor not found for player #{player_id}")

      [{_pid, _value}] ->
        Logger.info("Villager supervisor found for player #{player_id}, starting villagers...")

        Enum.each(villagers, fn villager ->
          # Extract villager name from the villager entity
          villager_name = villager.name
          villager_id = villager.id

          # Start the villager server process
          case Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 villager_id,
                 villager_name,
                 player_id
               ) do
            {:ok, _pid} ->
              Logger.info("Started villager server for #{villager_name} (#{villager_id})")

            {:error, reason} ->
              Logger.warning(
                "Failed to start villager server for #{villager_name} (#{villager_id}): #{inspect(reason)}"
              )
          end
        end)
    end
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
  def handle_info(:start_villager_servers, player) do
    # Start villager server processes for the default villagers
    start_villager_servers(player.kingdom.villagers, player.id)
    {:noreply, player}
  end

  @impl true
  def handle_info(:tick, player) do
    try do
      # Get current world time for immersive logging
      world_state = Everstead.Simulation.World.Server.get_state()
      year_name = Everstead.World.year_name(world_state.season.year)

      time_str =
        "Year #{world_state.season.year} (#{year_name}) - Day #{Everstead.World.day_of_season(world_state.season)}, #{Everstead.World.clock_time(world_state.season)} (#{Everstead.World.time_of_day(world_state.season)}) - #{Everstead.World.season_to_string(world_state.season.current)}"

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
              Logger.warning(
                "#{time_str} | Villager #{villager_id} has left the kingdom: #{inspect(reason)}"
              )

              acc

            error ->
              Logger.error(
                "#{time_str} | Error getting villager #{villager_id} state: #{inspect(error)}"
              )

              acc
          end
        end)

      # Tell JobManager to assign jobs to idle villagers
      try do
        job_manager_name =
          {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_#{player.id}"}}

        Everstead.Simulation.Kingdom.JobManager.Server.assign_jobs(job_manager_name, villager_map)

        # Log kingdom activity
        active_villagers =
          Enum.count(villager_map, fn {_id, villager} -> villager.state == :working end)

        idle_villagers =
          Enum.count(villager_map, fn {_id, villager} -> villager.state == :idle end)

        if active_villagers > 0 or idle_villagers > 0 do
          Logger.debug(
            "#{time_str} | Kingdom of #{player.kingdom.name}: #{active_villagers} working, #{idle_villagers} idle"
          )
        end
      catch
        error ->
          Logger.error("#{time_str} | Error assigning jobs to villagers: #{inspect(error)}")
      end

      {:noreply, player}
    catch
      error ->
        Logger.error("Error in player tick for #{player.id}: #{inspect(error)}")
        {:noreply, player}
    end
  end
end
