defmodule Everstead.Simulation.Kingdom.Villager.SupervisorTest do
  use ExUnit.Case, async: false
  alias Everstead.Simulation.Kingdom.Villager.Supervisor

  setup do
    # Create a unique test player ID to avoid conflicts
    test_id = :erlang.unique_integer([:positive]) |> Integer.to_string()
    timestamp = System.system_time(:millisecond)
    player_id = "villager_test_player_#{test_id}_#{timestamp}"

    # Start the villager supervisor directly for testing
    villager_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "villagers_#{player_id}"}}

    {:ok, villager_supervisor_pid} =
      Everstead.Simulation.Kingdom.Villager.Supervisor.start_link(villager_supervisor_name)

    %{
      villager_supervisor_pid: villager_supervisor_pid,
      villager_supervisor_name: villager_supervisor_name,
      player_id: player_id
    }
  end

  # Clean up after each test
  setup do
    on_exit(fn ->
      # Clean up all villagers from the registry
      all_villagers =
        Registry.select(Everstead.VillagerRegistry, [
          {{:"$1", :"$2", :"$3"}, [], [:"$1", :"$2", :"$3"]}
        ])

      Enum.each(all_villagers, fn entry ->
        case entry do
          {_villager_id, pid, _value} when is_pid(pid) ->
            try do
              Process.exit(pid, :kill)
            catch
              :exit, _ -> :ok
            end

          _ ->
            :ok
        end
      end)

      # Also clean up any remaining villager supervisors
      all_supervisors =
        Registry.select(Everstead.KingdomRegistry, [
          {{:"$1", :"$2", :"$3"}, [], [:"$1", :"$2", :"$3"]}
        ])

      Enum.each(all_supervisors, fn entry ->
        case entry do
          {key, pid, _value} when is_binary(key) and is_pid(pid) ->
            if String.starts_with?(key, "villagers_") do
              try do
                Process.exit(pid, :kill)
              catch
                :exit, _ -> :ok
              end
            end

          _ ->
            :ok
        end
      end)
    end)
  end

  describe "start_villager/3" do
    test "starts a new villager server", %{player_id: player_id} do
      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Test Villager",
                 player_id
               )
    end

    test "starts multiple villagers", %{player_id: player_id} do
      assert {:ok, _pid1} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert {:ok, _pid2} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v2",
                 "Villager 2",
                 player_id
               )
    end

    test "returns error when trying to start duplicate villager ID", %{player_id: player_id} do
      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert {:error, _reason} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1 Duplicate",
                 player_id
               )
    end
  end

  describe "stop_villager/1" do
    test "returns error when stopping non-existent villager" do
      assert {:error, :not_found} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.stop_villager("nonexistent")
    end
  end

  describe "list_villagers/0" do
    test "returns empty list when no villagers" do
      assert Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers() == []
    end

    test "returns list of active villager IDs", %{player_id: player_id} do
      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v2",
                 "Villager 2",
                 player_id
               )

      villagers = Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()
      assert length(villagers) == 2
      assert "v1" in villagers
      assert "v2" in villagers
    end

    test "villagers persist after being stopped due to restart strategy", %{player_id: player_id} do
      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v2",
                 "Villager 2",
                 player_id
               )

      assert length(Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()) == 2

      # Stop villager v1 - it should be restarted due to permanent restart strategy
      assert :ok = Everstead.Simulation.Kingdom.Villager.Supervisor.stop_villager("v1")
      # Wait a bit for the restart
      Process.sleep(50)

      # Villager v1 should still be in the list (restarted)
      assert length(Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()) == 2
      assert "v1" in Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()
      assert "v2" in Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()
    end
  end

  describe "count_villagers/0" do
    test "returns 0 when no villagers" do
      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 0
    end

    test "returns correct count of active villagers", %{player_id: player_id} do
      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 0

      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 1

      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v2",
                 "Villager 2",
                 player_id
               )

      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 2
    end

    test "villagers persist after being stopped due to restart strategy", %{player_id: player_id} do
      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v1",
                 "Villager 1",
                 player_id
               )

      assert {:ok, _pid} =
               Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager(
                 "v2",
                 "Villager 2",
                 player_id
               )

      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 2

      # Stop villager v1 - it should be restarted due to permanent restart strategy
      assert :ok = Everstead.Simulation.Kingdom.Villager.Supervisor.stop_villager("v1")
      # Wait a bit for the restart
      Process.sleep(50)

      # Villager v1 should still be in the list (restarted)
      assert Everstead.Simulation.Kingdom.Villager.Supervisor.count_villagers() == 2
      assert "v1" in Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()
      assert "v2" in Everstead.Simulation.Kingdom.Villager.Supervisor.list_villagers()
    end
  end

  describe "broadcast_tick/0" do
    test "sends tick message to all villagers", %{player_id: player_id} do
      assert {:ok, _pid} = Supervisor.start_villager("v1", "Villager 1", player_id)
      assert {:ok, _pid} = Supervisor.start_villager("v2", "Villager 2", player_id)

      # This should not raise an error
      assert :ok = Supervisor.broadcast_tick()
    end

    test "broadcast_tick returns ok even with no villagers" do
      # This should not raise an error even with no villagers
      assert :ok = Supervisor.broadcast_tick()
    end
  end

  describe "supervisor crash recovery" do
    test "supervisor restarts crashed villager server", %{player_id: player_id} do
      assert {:ok, villager_pid} = Supervisor.start_villager("v1", "Test Villager", player_id)

      # Kill the villager process
      Process.exit(villager_pid, :kill)
      Process.sleep(50)

      # Check that a new villager was started
      villagers = Supervisor.list_villagers()
      assert "v1" in villagers
    end
  end
end
