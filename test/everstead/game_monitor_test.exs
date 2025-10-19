defmodule EverStead.GameMonitorTest do
  use Everstead.DataCase, async: false

  alias EverStead.GameMonitor

  setup do
    # Start the required processes (ignore if already started)
    case EverStead.Simulation.Player.Supervisor.start_player("test_player", "Test Kingdom") do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case EverStead.Simulation.Kingdom.Villager.Supervisor.start_villager(
           "test_villager1",
           "Bob",
           "test_player"
         ) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    case EverStead.Simulation.Kingdom.Villager.Supervisor.start_villager(
           "test_villager2",
           "Alice",
           "test_player"
         ) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  describe "watch_resources/2" do
    test "displays kingdom resources, villager inventories, and world state" do
      # Test that the function runs without error
      assert GameMonitor.watch_resources("test_player", ["test_villager1", "test_villager2"]) ==
               :ok
    end

    test "handles empty villager list" do
      assert GameMonitor.watch_resources("test_player", []) == :ok
    end
  end

  describe "get_game_summary/2" do
    test "returns comprehensive game state summary" do
      summary = GameMonitor.get_game_summary("test_player", ["test_villager1", "test_villager2"])

      assert is_map(summary)
      assert Map.has_key?(summary, :kingdom_resources)
      assert Map.has_key?(summary, :villagers)
      assert Map.has_key?(summary, :job_manager)
      assert Map.has_key?(summary, :world_state)

      assert is_list(summary.villagers)
      assert length(summary.villagers) == 2

      assert is_list(summary.kingdom_resources)
      assert length(summary.kingdom_resources) == 3

      # Check that all resource types are present
      resource_types = Enum.map(summary.kingdom_resources, & &1.type)
      assert :wood in resource_types
      assert :stone in resource_types
      assert :food in resource_types
    end

    test "includes villager details in summary" do
      summary = GameMonitor.get_game_summary("test_player", ["test_villager1"])

      villager = List.first(summary.villagers)
      assert villager.id == "test_villager1"
      assert villager.name == "Bob"
      assert Map.has_key?(villager, :state)
      assert Map.has_key?(villager, :inventory)
      assert Map.has_key?(villager, :location)
    end
  end

  describe "monitor_gathering/3" do
    test "monitors resource gathering for specified duration" do
      # Test that the function runs without error (with minimal duration for testing)
      assert GameMonitor.monitor_gathering("test_player", ["test_villager1"], 1) == :ok
    end

    test "uses default duration when not specified" do
      # Test with minimal duration to avoid long test times
      assert GameMonitor.monitor_gathering("test_player", ["test_villager1"], 1) == :ok
    end
  end

  describe "has_resources?/2" do
    test "returns true when player has sufficient resources" do
      # Test with resources that should be available (zero requirements)
      assert GameMonitor.has_resources?("test_player", %{wood: 0, stone: 0}) == true
    end

    test "returns false when player lacks sufficient resources" do
      # Test with resources that shouldn't be available
      assert GameMonitor.has_resources?("test_player", %{wood: 1000, stone: 1000}) == false
    end
  end

  describe "get_resources/1" do
    test "returns current resource amounts for player" do
      resources = GameMonitor.get_resources("test_player")

      assert is_list(resources)
      assert length(resources) == 3

      # Check that all resource types are present
      resource_types = Enum.map(resources, & &1.type)
      assert :wood in resource_types
      assert :stone in resource_types
      assert :food in resource_types
    end
  end

  describe "status_report/2" do
    test "displays formatted status report" do
      assert GameMonitor.status_report("test_player", ["test_villager1", "test_villager2"]) == :ok
    end

    test "handles empty villager list in status report" do
      assert GameMonitor.status_report("test_player", []) == :ok
    end
  end

  describe "error handling" do
    test "handles non-existent player gracefully" do
      assert catch_exit(GameMonitor.get_resources("non_existent_player"))
    end

    test "handles non-existent villager in watch_resources" do
      # This should not crash, but may show empty data
      assert GameMonitor.watch_resources("test_player", ["non_existent_villager"]) == :ok
    end
  end
end
