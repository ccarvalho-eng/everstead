defmodule Everstead.TestHelpers do
  @moduledoc """
  Test helpers for setting up the proper supervision hierarchy.
  """

  @doc """
  Sets up a test player with kingdom supervisor and returns the kingdom supervisor name.
  """
  def setup_test_player(player_id \\ "test_player") do
    # Start a test player (handle case where it's already started)
    case Everstead.Simulation.Player.DynamicSupervisor.start_player(player_id, "Test Player") do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> raise "Failed to start player: #{inspect(reason)}"
    end

    # Return the kingdom supervisor name for this player
    {:via, Registry, {Everstead.KingdomRegistry, "kingdom_#{player_id}"}}
  end

  @doc """
  Gets the JobManager for a specific kingdom.
  """
  def get_job_manager_for_kingdom(kingdom_id) do
    # JobManager is supervised by Kingdom.Supervisor, so we need to get it from there
    kingdom_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "kingdom_#{kingdom_id}"}}

    # Get the JobManager child from the kingdom supervisor
    children = Supervisor.which_children(kingdom_supervisor_name)

    job_manager_pid =
      children
      |> Enum.find(fn {id, _pid, _type, _modules} ->
        id == Everstead.Simulation.Kingdom.JobManager.Server
      end)
      |> case do
        {_id, pid, _type, _modules} -> pid
        nil -> nil
      end

    job_manager_pid
  end

  @doc """
  Gets the villager supervisor name for a test player.
  """
  def get_villager_supervisor_name(player_id \\ "test_player") do
    {:via, Registry, {Everstead.KingdomRegistry, "villagers_#{player_id}"}}
  end

  @doc """
  Starts a villager for a test player.
  """
  def start_test_villager(villager_id, villager_name, player_id \\ "test_player") do
    Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
      villager_id,
      villager_name,
      player_id
    )
  end
end
