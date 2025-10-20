defmodule Everstead.Simulation.World.Server do
  @moduledoc """
  Central world simulation server that drives the game tick cycle.

  The WorldServer is responsible for coordinating the entire game simulation
  by emitting periodic tick events every second. These ticks trigger updates
  across all active player servers and their associated game entities.

  ## Tick Cycle
  - Fires every 1000ms (1 second)
  - Broadcasts tick events to all player servers
  - Advances season progression
  - Reschedules itself for continuous simulation

  ## Season System
  Tracks the current season (Spring, Summer, Fall, Winter) and year,
  automatically progressing through seasons based on tick count.
  Features immersive time formatting with named years and day/night cycles.
  """
  use GenServer

  require Logger

  alias Everstead.Entities.World.Season
  alias Everstead.World

  @tick_interval 1_000

  # Client API

  @doc """
  Starts the world server.

  The server is registered with its module name and begins the tick cycle immediately.
  """
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Gets the current season information.

  Returns a Season struct containing the current season, elapsed ticks, and year.

  ## Examples

      iex> WorldServer.get_season()
      %Season{current: :spring, ticks_elapsed: 42, year: 1}
  """
  @spec get_season() :: Season.t()
  def get_season do
    GenServer.call(__MODULE__, :get_season)
  end

  @doc """
  Gets the current world state including season and tick count.

  ## Examples

      iex> WorldServer.get_state()
      %{season: %Season{...}, total_ticks: 150}
  """
  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  # Server callbacks

  @impl true
  def init(_state) do
    schedule_tick()
    {:ok, %{season: %Season{}, total_ticks: 0}}
  end

  @impl true
  def handle_info(:tick, state) do
    new_season = World.tick_season(state.season)
    new_total_ticks = state.total_ticks + 1

    # Log season changes with immersive descriptions
    if new_season.current != state.season.current do
      year_name = World.year_name(new_season.year)
      old_season = World.season_to_string(state.season.current)
      new_season_name = World.season_to_string(new_season.current)

      Logger.info(
        "#{year_name} - The season turns from #{old_season} to #{new_season_name}. " <>
          "The world awakens to new possibilities..."
      )
    end

    # Create immersive daily logs
    # Every 60 ticks (full day cycle)
    if rem(new_total_ticks, 60) == 0 do
      time = World.time_of_day(new_season)
      weather = World.get_weather(new_season.current, time)
      world_event = World.get_world_event(new_season.current, time)
      year_name = World.year_name(new_season.year)

      Logger.info(
        "Year #{new_season.year} (#{year_name}) - Day #{World.day_of_season(new_season)}, #{time} - #{World.season_to_string(new_season.current)} | #{weather} | #{world_event}"
      )
    else
      # Show clock progression in debug logs
      clock_time = World.clock_time(new_season)
      year_name = World.year_name(new_season.year)

      Logger.debug(
        "Year #{new_season.year} (#{year_name}) - Day #{World.day_of_season(new_season)}, #{clock_time} (#{World.time_of_day(new_season)}) - #{World.season_to_string(new_season.current)}"
      )
    end

    # Broadcast tick to all PlayerServers and VillagerServers
    Everstead.Simulation.Player.DynamicSupervisor.broadcast_tick()
    Everstead.Simulation.Kingdom.Villager.Supervisor.broadcast_tick()

    schedule_tick()
    {:noreply, %{state | season: new_season, total_ticks: new_total_ticks}}
  end

  @impl true
  def handle_call(:get_season, _from, state) do
    {:reply, state.season, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end
end
