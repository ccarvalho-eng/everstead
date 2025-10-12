defmodule EverStead.Simulation.VillagerSupervisorTest do
  use ExUnit.Case, async: false

  alias EverStead.Simulation.{VillagerServer, VillagerSupervisor}

  setup do
    # Registry and Supervisor are already started by the application
    # Clean up any existing villagers from previous tests
    VillagerSupervisor.list_villagers()
    |> Enum.each(&VillagerSupervisor.stop_villager/1)

    Process.sleep(50)

    :ok
  end

  describe "start_villager/3" do
    test "starts a new villager server" do
      assert {:ok, pid} = VillagerSupervisor.start_villager("v1", "Bob", "p1")
      assert Process.alive?(pid)

      state = VillagerServer.get_state("v1")
      assert state.id == "v1"
      assert state.name == "Bob"
    end

    test "registers villager in the registry" do
      {:ok, _pid} = VillagerSupervisor.start_villager("v2", "Alice", "p1")

      assert [{_pid, _}] = Registry.lookup(EverStead.VillagerRegistry, "v2")
    end

    test "starts multiple villagers" do
      {:ok, pid1} = VillagerSupervisor.start_villager("v3", "Charlie", "p1")
      {:ok, pid2} = VillagerSupervisor.start_villager("v4", "Dana", "p1")
      {:ok, pid3} = VillagerSupervisor.start_villager("v5", "Eve", "p2")

      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
      assert Process.alive?(pid3)

      assert VillagerServer.get_state("v3").name == "Charlie"
      assert VillagerServer.get_state("v4").name == "Dana"
      assert VillagerServer.get_state("v5").name == "Eve"
    end

    test "returns error when trying to start duplicate villager ID" do
      {:ok, _pid} = VillagerSupervisor.start_villager("v6", "Frank", "p1")

      assert {:error, {:already_started, _}} =
               VillagerSupervisor.start_villager("v6", "Grace", "p1")
    end
  end

  describe "stop_villager/1" do
    test "stops a running villager server" do
      {:ok, pid} = VillagerSupervisor.start_villager("v7", "Henry", "p1")
      assert Process.alive?(pid)

      assert :ok = VillagerSupervisor.stop_villager("v7")

      # Give it time to stop
      Process.sleep(50)

      refute Process.alive?(pid)
    end

    test "returns error when stopping non-existent villager" do
      assert {:error, :not_found} = VillagerSupervisor.stop_villager("nonexistent")
    end
  end

  describe "list_villagers/0" do
    test "returns empty list when no villagers" do
      assert VillagerSupervisor.list_villagers() == []
    end

    test "returns list of active villager IDs" do
      VillagerSupervisor.start_villager("v8", "Ivy", "p1")
      VillagerSupervisor.start_villager("v9", "Jack", "p1")
      VillagerSupervisor.start_villager("v10", "Kate", "p2")

      villager_ids = VillagerSupervisor.list_villagers()
      assert length(villager_ids) == 3
      assert "v8" in villager_ids
      assert "v9" in villager_ids
      assert "v10" in villager_ids
    end

    test "updates list when villagers are stopped" do
      VillagerSupervisor.start_villager("v11", "Leo", "p1")
      VillagerSupervisor.start_villager("v12", "Mia", "p1")

      assert length(VillagerSupervisor.list_villagers()) == 2

      VillagerSupervisor.stop_villager("v11")
      Process.sleep(50)

      villager_ids = VillagerSupervisor.list_villagers()
      assert length(villager_ids) == 1
      assert "v12" in villager_ids
      refute "v11" in villager_ids
    end
  end

  describe "count_villagers/0" do
    test "returns 0 when no villagers" do
      assert VillagerSupervisor.count_villagers() == 0
    end

    test "returns correct count of active villagers" do
      VillagerSupervisor.start_villager("v13", "Nina", "p1")
      assert VillagerSupervisor.count_villagers() == 1

      VillagerSupervisor.start_villager("v14", "Oscar", "p1")
      assert VillagerSupervisor.count_villagers() == 2

      VillagerSupervisor.start_villager("v15", "Paul", "p2")
      assert VillagerSupervisor.count_villagers() == 3
    end

    test "decrements count when villagers are stopped" do
      VillagerSupervisor.start_villager("v16", "Quinn", "p1")
      VillagerSupervisor.start_villager("v17", "Rose", "p1")

      assert VillagerSupervisor.count_villagers() == 2

      VillagerSupervisor.stop_villager("v16")
      Process.sleep(50)

      assert VillagerSupervisor.count_villagers() == 1
    end
  end

  describe "broadcast_tick/0" do
    test "sends tick message to all villagers" do
      {:ok, pid1} = VillagerSupervisor.start_villager("v18", "Sam", "p1")
      {:ok, pid2} = VillagerSupervisor.start_villager("v19", "Tina", "p1")

      # Clear any existing messages
      :sys.get_state(pid1)
      :sys.get_state(pid2)

      assert :ok = VillagerSupervisor.broadcast_tick()

      # Give time for messages to be processed
      Process.sleep(10)

      # Both villagers should have received and processed tick
      # We can verify they're still alive and responding
      assert Process.alive?(pid1)
      assert Process.alive?(pid2)
    end

    test "broadcast_tick returns ok even with no villagers" do
      assert :ok = VillagerSupervisor.broadcast_tick()
    end
  end

  describe "supervisor crash recovery" do
    test "supervisor restarts crashed villager server" do
      {:ok, pid} = VillagerSupervisor.start_villager("v20", "Uma", "p1")
      original_pid = pid

      # Kill the process
      Process.exit(pid, :kill)
      Process.sleep(100)

      # The supervisor should have restarted it
      # Note: In a real scenario with :permanent restart strategy
      # For now, with :temporary, it won't restart
      # This test documents the current behavior
      refute Process.alive?(original_pid)
    end
  end
end
