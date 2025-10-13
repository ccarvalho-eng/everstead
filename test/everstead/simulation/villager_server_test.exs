defmodule EverStead.Simulation.Kingdom.Villager.ServerTest do
  use ExUnit.Case, async: false

  alias EverStead.Simulation.Kingdom.Villager.{Server, Supervisor}
  alias EverStead.Entities.World.Kingdom.Villager
  alias EverStead.Entities.World.Kingdom.Job
  alias EverStead.Entities.World.Resource

  setup do
    # Registry and Supervisor are already started by the application
    # Clean up any existing villagers from previous tests
    Supervisor.list_villagers()
    |> Enum.each(&Supervisor.stop_villager/1)

    Process.sleep(50)

    :ok
  end

  describe "start_link/1" do
    test "starts a villager server with valid parameters" do
      assert {:ok, pid} = Server.start_link({"v1", "Bob", "p1"})
      assert Process.alive?(pid)

      state = Server.get_state("v1")
      assert state.id == "v1"
      assert state.name == "Bob"
      assert state.state == :idle
      assert state.location == {0, 0}
    end

    test "registers villager in VillagerRegistry" do
      {:ok, _pid} = Server.start_link({"v2", "Alice", "p1"})

      assert [{_pid, _}] = Registry.lookup(EverStead.VillagerRegistry, "v2")
    end
  end

  describe "get_state/1" do
    test "returns the current villager state" do
      {:ok, _pid} = Server.start_link({"v3", "Charlie", "p1"})

      state = Server.get_state("v3")
      assert %Villager{} = state
      assert state.id == "v3"
      assert state.name == "Charlie"
      assert state.state == :idle
    end
  end

  describe "assign_job/2" do
    test "assigns a gathering job to a villager" do
      {:ok, _pid} = Server.start_link({"v4", "Dana", "p1"})

      job = %Job{
        id: "j1",
        type: :gather,
        target: %Resource{type: :wood, location: {5, 5}},
        status: :pending
      }

      assert :ok = Server.assign_job("v4", job)

      # Give it a moment to process
      Process.sleep(10)

      state = Server.get_state("v4")
      assert state.state == :working
    end

    test "assigns a building job to a villager" do
      {:ok, _pid} = Server.start_link({"v5", "Eve", "p1"})

      job = %Job{
        id: "j2",
        type: :build,
        target: %{location: {3, 3}},
        status: :pending
      }

      assert :ok = Server.assign_job("v5", job)
      Process.sleep(10)

      state = Server.get_state("v5")
      assert state.state == :working
    end

    test "assigns a movement job to a villager" do
      {:ok, _pid} = Server.start_link({"v6", "Frank", "p1"})

      job = %Job{
        id: "j3",
        type: :move,
        target: %{location: {10, 10}},
        status: :pending
      }

      assert :ok = Server.assign_job("v6", job)
      Process.sleep(10)

      state = Server.get_state("v6")
      assert state.state == :working
    end
  end

  describe "cancel_job/1" do
    test "cancels current job and returns villager to idle" do
      {:ok, _pid} = Server.start_link({"v7", "Grace", "p1"})

      job = %Job{
        id: "j4",
        type: :gather,
        target: %Resource{type: :stone, location: {2, 2}},
        status: :pending
      }

      Server.assign_job("v7", job)
      Process.sleep(10)

      state = Server.get_state("v7")
      assert state.state == :working

      assert :ok = Server.cancel_job("v7")
      Process.sleep(10)

      state = Server.get_state("v7")
      assert state.state == :idle
    end
  end

  describe "tick processing - gathering" do
    test "villager gathers wood when assigned gathering job" do
      {:ok, pid} = Server.start_link({"v8", "Henry", "p1"})

      job = %Job{
        id: "j5",
        type: :gather,
        target: %Resource{type: :wood, location: {1, 1}},
        status: :in_progress
      }

      Server.assign_job("v8", job)
      Process.sleep(10)

      # Simulate a tick
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v8")
      assert state.inventory[:wood] == 5
    end

    test "villager gathers stone when assigned gathering job" do
      {:ok, pid} = Server.start_link({"v9", "Ivy", "p1"})

      job = %Job{
        id: "j6",
        type: :gather,
        target: %Resource{type: :stone, location: {2, 2}},
        status: :in_progress
      }

      Server.assign_job("v9", job)
      Process.sleep(10)

      # Simulate a tick
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v9")
      assert state.inventory[:stone] == 3
    end

    test "villager gathers food when assigned gathering job" do
      {:ok, pid} = Server.start_link({"v10", "Jack", "p1"})

      job = %Job{
        id: "j7",
        type: :gather,
        target: %Resource{type: :food, location: {3, 3}},
        status: :in_progress
      }

      Server.assign_job("v10", job)
      Process.sleep(10)

      # Simulate a tick
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v10")
      assert state.inventory[:food] == 8
    end

    test "villager accumulates resources over multiple ticks" do
      {:ok, pid} = Server.start_link({"v11", "Kate", "p1"})

      job = %Job{
        id: "j8",
        type: :gather,
        target: %Resource{type: :wood, location: {1, 1}},
        status: :in_progress
      }

      Server.assign_job("v11", job)
      Process.sleep(10)

      # Simulate multiple ticks
      send(pid, :tick)
      Process.sleep(10)
      send(pid, :tick)
      Process.sleep(10)
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v11")
      assert state.inventory[:wood] == 15
    end
  end

  describe "tick processing - movement" do
    test "villager moves towards target location" do
      {:ok, pid} = Server.start_link({"v12", "Leo", "p1"})

      job = %Job{
        id: "j9",
        type: :move,
        target: %{location: {5, 5}},
        status: :in_progress
      }

      Server.assign_job("v12", job)
      Process.sleep(10)

      initial_state = Server.get_state("v12")
      assert initial_state.location == {0, 0}

      # Simulate tick
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v12")
      # Should move 1 tile towards target
      assert state.location == {1, 1}
      assert state.state == :moving
    end

    test "villager becomes idle when reaching destination" do
      {:ok, pid} = Server.start_link({"v13", "Mia", "p1"})

      # Set up villager close to destination
      job = %Job{
        id: "j10",
        type: :move,
        target: %{location: {1, 1}},
        status: :in_progress
      }

      Server.assign_job("v13", job)
      Process.sleep(10)

      # First tick - move to destination
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v13")
      assert state.location == {1, 1}

      # Second tick - realize we're at destination and become idle
      send(pid, :tick)
      Process.sleep(10)

      state = Server.get_state("v13")
      assert state.location == {1, 1}
      assert state.state == :idle
    end
  end

  describe "get_gathering_rate/1" do
    test "returns correct rates for each resource type" do
      assert Server.get_gathering_rate(:wood) == 5
      assert Server.get_gathering_rate(:stone) == 3
      assert Server.get_gathering_rate(:food) == 8
    end

    test "returns default rate for unknown resource" do
      assert Server.get_gathering_rate(:unknown) == 5
    end
  end

  describe "get_movement_speed/0" do
    test "returns movement speed" do
      assert Server.get_movement_speed() == 1
    end
  end
end
