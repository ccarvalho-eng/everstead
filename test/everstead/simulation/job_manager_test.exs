defmodule Everstead.Simulation.Kingdom.JobManagerTest do
  use ExUnit.Case, async: true
  alias Everstead.Simulation.Kingdom.JobManager.Server
  alias Everstead.Entities.World.Kingdom.Job
  alias Everstead.Entities.World.Resource

  setup do
    # Create a unique test player ID to avoid conflicts
    test_id = :erlang.unique_integer([:positive]) |> Integer.to_string()
    player_id = "job_test_player_#{test_id}"

    # Start JobManager directly for testing
    job_manager_name = {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_#{player_id}"}}

    {:ok, job_manager_pid} =
      Everstead.Simulation.Kingdom.JobManager.Server.start_link(job_manager_name)

    %{job_manager: job_manager_pid, player_id: player_id}
  end

  describe "add_job/2" do
    test "adds a job to the queue with default priority", %{
      job_manager: job_manager,
      player_id: player_id
    } do
      job = %Job{
        id: "j1",
        type: :gather,
        target: %Resource{type: :wood, location: {5, 5}},
        status: :pending
      }

      job_manager_name = Server.get_for_kingdom(player_id)
      assert :ok = GenServer.cast(job_manager_name, {:add_job, job, :normal})
      Process.sleep(10)

      state = GenServer.call(job_manager, :get_state)
      assert length(state.job_queue) == 1
      assert {^job, :normal} = List.first(state.job_queue)
    end

    test "adds a job with specified priority", %{job_manager: job_manager, player_id: player_id} do
      job = %Job{
        id: "j2",
        type: :build,
        target: %Resource{type: :stone, location: {10, 10}},
        status: :pending
      }

      job_manager_name = Server.get_for_kingdom(player_id)
      assert :ok = GenServer.cast(job_manager_name, {:add_job, job, :high})
      Process.sleep(10)

      state = GenServer.call(job_manager, :get_state)
      assert length(state.job_queue) == 1
      assert {^job, :high} = List.first(state.job_queue)
    end
  end

  describe "get_state/0" do
    test "returns current state with queue, active jobs, and stats", %{job_manager: job_manager} do
      state = GenServer.call(job_manager, :get_state)

      assert is_map(state)
      assert Map.has_key?(state, :job_queue)
      assert Map.has_key?(state, :active_jobs)
      assert Map.has_key?(state, :stats)
      assert is_list(state.job_queue)
      assert is_map(state.active_jobs)
      assert is_map(state.stats)
    end
  end

  describe "clear_all_jobs/0" do
    test "clears all jobs from queue and active jobs", %{
      job_manager: job_manager,
      player_id: player_id
    } do
      job = %Job{
        id: "j3",
        type: :gather,
        target: %Resource{type: :wood, location: {5, 5}},
        status: :pending
      }

      job_manager_name = Server.get_for_kingdom(player_id)
      assert :ok = GenServer.cast(job_manager_name, {:add_job, job, :normal})
      Process.sleep(10)

      state = GenServer.call(job_manager, :get_state)
      assert length(state.job_queue) == 1

      assert :ok = GenServer.cast(job_manager_name, :clear_all_jobs)
      Process.sleep(10)

      state = GenServer.call(job_manager, :get_state)
      assert length(state.job_queue) == 0
      assert map_size(state.active_jobs) == 0
    end
  end
end
