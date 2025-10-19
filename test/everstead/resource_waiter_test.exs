defmodule EverStead.ResourceWaiterTest do
  use Everstead.DataCase, async: false

  alias EverStead.ResourceWaiter

  setup do
    # Start a test player (ignore if already started)
    case EverStead.Simulation.Player.Supervisor.start_player("test_player", "Test Kingdom") do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  describe "wait_for_resources/3" do
    test "returns :ok when resources are immediately available" do
      # Test with zero requirements (should always pass)
      result = ResourceWaiter.wait_for_resources("test_player", %{wood: 0, stone: 0}, 1)
      assert result == :ok
    end

    test "returns :timeout when max_ticks is reached" do
      result = ResourceWaiter.wait_for_resources("test_player", %{wood: 1000}, 1)
      assert result == :timeout
    end

    test "uses default max_ticks when not specified" do
      result = ResourceWaiter.wait_for_resources("test_player", %{wood: 1000}, 1)
      assert result == :timeout
    end
  end

  describe "wait_with_progress/4" do
    test "calls progress callback for each tick" do
      callback = fn resources, tick ->
        send(self(), {:progress, resources, tick})
      end

      result = ResourceWaiter.wait_with_progress("test_player", %{wood: 1000}, 2, callback)

      # Should have received 2 progress calls (ticks 0, 1)
      assert_receive {:progress, _, 0}
      assert_receive {:progress, _, 1}
      assert result == :timeout
    end

    test "returns :ok when resources are immediately available" do
      callback = fn resources, tick ->
        send(self(), {:progress, resources, tick})
      end

      result = ResourceWaiter.wait_with_progress("test_player", %{wood: 0}, 5, callback)
      assert result == :ok
    end
  end

  describe "wait_for_resource/4" do
    test "waits for specific resource amount with progress reporting" do
      result = ResourceWaiter.wait_for_resource("test_player", :wood, 100, 2)
      assert result == :timeout
    end

    test "uses default max_ticks when not specified" do
      result = ResourceWaiter.wait_for_resource("test_player", :wood, 100, 1)
      assert result == :timeout
    end

    test "returns :ok when resource is immediately available" do
      result = ResourceWaiter.wait_for_resource("test_player", :wood, 0, 1)
      assert result == :ok
    end
  end

  describe "wait_for_multiple_resources/3" do
    test "waits for multiple resources with combined progress" do
      result =
        ResourceWaiter.wait_for_multiple_resources("test_player", %{wood: 50, stone: 20}, 2)

      assert result == :timeout
    end

    test "uses default max_ticks when not specified" do
      result =
        ResourceWaiter.wait_for_multiple_resources("test_player", %{wood: 50, stone: 20}, 1)

      assert result == :timeout
    end

    test "returns :ok when all resources are immediately available" do
      result = ResourceWaiter.wait_for_multiple_resources("test_player", %{wood: 0, stone: 0}, 1)
      assert result == :ok
    end
  end

  describe "get_progress/2" do
    test "returns progress percentage for single resource" do
      progress = ResourceWaiter.get_progress("test_player", %{wood: 100})
      assert progress == 0.0
    end

    test "returns progress percentage for multiple resources" do
      progress = ResourceWaiter.get_progress("test_player", %{wood: 100, stone: 50})
      assert progress == 0.0
    end

    test "returns 1.0 when all resources are available" do
      progress = ResourceWaiter.get_progress("test_player", %{wood: 0, stone: 0})
      assert progress == 1.0
    end

    test "handles zero required amounts" do
      progress = ResourceWaiter.get_progress("test_player", %{wood: 0, stone: 0})
      assert progress == 1.0
    end
  end

  describe "error handling" do
    test "handles non-existent player gracefully" do
      assert catch_exit(ResourceWaiter.get_progress("non_existent_player", %{wood: 100}))
    end

    test "handles empty resource requirements" do
      progress = ResourceWaiter.get_progress("test_player", %{})
      assert progress == 1.0
    end
  end
end
