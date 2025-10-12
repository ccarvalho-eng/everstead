defmodule EverStead.Simulation.WorldServer do
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
  """
  use GenServer

  require Logger

  alias EverStead.Entities.Season

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
    new_season = Season.tick(state.season)
    new_total_ticks = state.total_ticks + 1

    # Log season changes
    if new_season.current != state.season.current do
      Logger.info(
        "Season changed: #{Season.to_string(state.season.current)} -> #{Season.to_string(new_season.current)} (Year #{new_season.year})"
      )
    end

    Logger.debug(
      "World tick ##{new_total_ticks} | #{Season.to_string(new_season.current)} - Day #{new_season.ticks_elapsed + 1}/#{Season.season_duration()}"
    )

    # Broadcast tick to all PlayerServers and VillagerServers
    EverStead.Simulation.PlayerSupervisor.broadcast_tick()
    EverStead.Simulation.VillagerSupervisor.broadcast_tick()

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
