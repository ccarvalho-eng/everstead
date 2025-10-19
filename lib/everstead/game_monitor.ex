defmodule EverStead.GameMonitor do
  @moduledoc """
  Utility module for monitoring game state and resource gathering progress.

  Provides functions to watch kingdom resources, villager inventories,
  job progress, and seasonal effects in real-time.
  """

  require Logger

  alias EverStead.Simulation.Player.Server, as: PlayerServer
  alias EverStead.Simulation.Kingdom.Villager.Server, as: VillagerServer
  alias EverStead.Simulation.Kingdom.JobManager
  alias EverStead.Simulation.World.Server, as: WorldServer
  alias EverStead.World

  @doc """
  Monitors and displays comprehensive game state for a player and their villagers.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `villager_ids` - List of villager IDs to monitor

  ## Examples

      iex> GameMonitor.watch_resources("player1", ["villager1", "villager2"])
      === Kingdom Resources ===
      %{wood: 0, stone: 0, food: 0}
      === Villager Inventories ===
      %{wood: 5, stone: 0, food: 0}
      State: :working
      ...
  """
  @spec watch_resources(String.t(), [String.t()]) :: :ok
  def watch_resources(player_id, villager_ids) do
    # Check kingdom resources
    player = PlayerServer.get_state(player_id)
    Logger.debug("=== Kingdom Resources ===")
    Logger.debug("Kingdom: #{inspect(player.kingdom.resources)}")

    # Check villager inventories
    Logger.debug("=== Villager Inventories ===")

    Enum.each(villager_ids, fn villager_id ->
      try do
        villager = VillagerServer.get_state(villager_id)
        Logger.debug("Villager #{villager_id}: #{inspect(villager.inventory)}")
        Logger.debug("State: #{villager.state}")
      catch
        :exit, _ -> Logger.debug("Villager #{villager_id}: Not found")
      end
    end)

    # Check job manager
    job_state = JobManager.get_state()
    Logger.debug("=== Job Manager ===")
    Logger.debug("Jobs in queue: #{length(job_state.job_queue)}")
    Logger.debug("Active jobs: #{map_size(job_state.active_jobs)}")

    # Check current season
    season = WorldServer.get_season()
    Logger.debug("=== World State ===")
    Logger.debug("Current season: #{World.season_to_string(season.current)}")
    Logger.debug("Ticks elapsed: #{season.ticks_elapsed}/60")
    Logger.debug("Year: #{season.year}")

    :ok
  end

  @doc """
  Gets a summary of the current game state as a map.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `villager_ids` - List of villager IDs to monitor

  ## Returns
  - `map()` - Summary of game state

  ## Examples

      iex> GameMonitor.get_game_summary("player1", ["villager1"])
      %{
        kingdom_resources: %{wood: 0, stone: 0, food: 0},
        villagers: [...],
        job_manager: %{...},
        world_state: %{...}
      }
  """
  @spec get_game_summary(String.t(), [String.t()]) :: map()
  def get_game_summary(player_id, villager_ids) do
    player = PlayerServer.get_state(player_id)
    job_state = JobManager.get_state()
    world_state = WorldServer.get_state()

    villagers =
      Enum.map(villager_ids, fn villager_id ->
        villager = VillagerServer.get_state(villager_id)

        %{
          id: villager.id,
          name: villager.name,
          state: villager.state,
          inventory: villager.inventory,
          location: villager.location
        }
      end)

    %{
      kingdom_resources: player.kingdom.resources,
      villagers: villagers,
      job_manager: %{
        jobs_in_queue: length(job_state.job_queue),
        active_jobs: map_size(job_state.active_jobs),
        stats: job_state.stats
      },
      world_state: %{
        season: world_state.season,
        total_ticks: world_state.total_ticks
      }
    }
  end

  @doc """
  Monitors resource gathering progress and displays updates.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `villager_ids` - List of villager IDs to monitor
  - `duration_seconds` - How long to monitor (default: 10)

  ## Examples

      iex> GameMonitor.monitor_gathering("player1", ["villager1"], 5)
      Monitoring resource gathering for 5 seconds...
      Tick 1: Wood: 5, Stone: 0, Food: 0
      Tick 2: Wood: 10, Stone: 3, Food: 0
      ...
  """
  @spec monitor_gathering(String.t(), [String.t()], integer()) :: :ok
  def monitor_gathering(player_id, _villager_ids, duration_seconds \\ 10) do
    Logger.debug("Monitoring resource gathering for #{duration_seconds} seconds...")

    Enum.each(1..duration_seconds, fn tick ->
      # Wait 1 second (1 tick)
      Process.sleep(1000)

      player = PlayerServer.get_state(player_id)
      resources = player.kingdom.resources

      Logger.debug(
        "Tick #{tick}: Wood: #{resources[:wood] || 0}, Stone: #{resources[:stone] || 0}, Food: #{resources[:food] || 0}"
      )
    end)

    :ok
  end

  @doc """
  Checks if a player has enough resources for a specific cost.

  ## Parameters
  - `player_id` - The ID of the player to check
  - `costs` - Map of resource types to required amounts

  ## Returns
  - `boolean()` - True if player has enough resources

  ## Examples

      iex> GameMonitor.has_resources?("player1", %{wood: 50, stone: 20})
      false
  """
  @spec has_resources?(String.t(), map()) :: boolean()
  def has_resources?(player_id, costs) do
    player = PlayerServer.get_state(player_id)
    EverStead.Kingdom.has_resources?(player.kingdom, costs)
  end

  @doc """
  Gets the current resource amounts for a player.

  ## Parameters
  - `player_id` - The ID of the player to check

  ## Returns
  - `map()` - Current resource amounts

  ## Examples

      iex> GameMonitor.get_resources("player1")
      %{wood: 0, stone: 0, food: 0}
  """
  @spec get_resources(String.t()) :: map()
  def get_resources(player_id) do
    player = PlayerServer.get_state(player_id)
    player.kingdom.resources
  end

  @doc """
  Displays a formatted status report for a player and their villagers.

  ## Parameters
  - `player_id` - The ID of the player to report on
  - `villager_ids` - List of villager IDs to include in report

  ## Examples

      iex> GameMonitor.status_report("player1", ["villager1"])
      ========================================
      KINGDOM STATUS REPORT
      ========================================
      Player: player1
      Resources: Wood: 0, Stone: 0, Food: 0
      Villagers: 1
      Active Jobs: 1
      Current Season: Spring (Day 1/60)
      ========================================
  """
  @spec status_report(String.t(), [String.t()]) :: :ok
  def status_report(player_id, villager_ids) do
    player = PlayerServer.get_state(player_id)
    job_state = JobManager.get_state()
    season = WorldServer.get_season()

    Logger.debug("========================================")
    Logger.debug("KINGDOM STATUS REPORT")
    Logger.debug("========================================")
    Logger.debug("Player: #{player_id}")

    Logger.debug(
      "Resources: Wood: #{player.kingdom.resources[:wood] || 0}, Stone: #{player.kingdom.resources[:stone] || 0}, Food: #{player.kingdom.resources[:food] || 0}"
    )

    Logger.debug("Villagers: #{length(villager_ids)}")
    Logger.debug("Active Jobs: #{map_size(job_state.active_jobs)}")

    Logger.debug(
      "Current Season: #{World.season_to_string(season.current)} (Day #{season.ticks_elapsed + 1}/60)"
    )

    Logger.debug("========================================")

    :ok
  end
end
