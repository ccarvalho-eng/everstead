defmodule EverStead.Simulation.JobManagerTest do
  use ExUnit.Case, async: false

  alias EverStead.Simulation.{JobManager, VillagerServer, VillagerSupervisor}
  alias EverStead.Entities.{Job, Resource}

  setup do
    # Clean up villagers from previous tests
    VillagerSupervisor.list_villagers()
    |> Enum.each(&VillagerSupervisor.stop_villager/1)

    # Clear all jobs
    JobManager.clear_all_jobs()

    Process.sleep(50)

    :ok
  end

  describe "add_job/2" do
    test "adds a job to the queue with default priority" do
      job = %Job{
        id: "j1",
        type: :gather,
        target: %Resource{type: :wood, location: {5, 5}},
        status: :pending
      }

      assert :ok = JobManager.add_job(job)
      Process.sleep(10)

      state = JobManager.get_state()
      assert length(state.job_queue) == 1
      assert {^job, :normal} = List.first(state.job_queue)
    end

    test "adds a job with specified priority" do
      job = %Job{
        id: "j2",
        type: :gather,
        target: %Resource{type: :stone, location: {3, 3}},
        status: :pending
      }

      assert :ok = JobManager.add_job(job, :high)
      Process.sleep(10)

      state = JobManager.get_state()
      assert {^job, :high} = List.first(state.job_queue)
    end

    test "maintains priority order when adding multiple jobs" do
      job_low = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}
      job_normal = %Job{id: "j2", type: :gather, target: %Resource{type: :stone}}
      job_high = %Job{id: "j3", type: :gather, target: %Resource{type: :food}}
      job_critical = %Job{id: "j4", type: :build, target: %{location: {1, 1}}}

      JobManager.add_job(job_low, :low)
      JobManager.add_job(job_normal, :normal)
      JobManager.add_job(job_high, :high)
      JobManager.add_job(job_critical, :critical)

      Process.sleep(50)

      state = JobManager.get_state()
      priorities = Enum.map(state.job_queue, fn {_job, priority} -> priority end)

      assert priorities == [:critical, :high, :normal, :low]
    end
  end

  describe "remove_job/1" do
    test "removes a job from the queue" do
      job1 = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}
      job2 = %Job{id: "j2", type: :gather, target: %Resource{type: :stone}}

      JobManager.add_job(job1)
      JobManager.add_job(job2)
      Process.sleep(10)

      state = JobManager.get_state()
      assert length(state.job_queue) == 2

      JobManager.remove_job("j1")
      Process.sleep(10)

      state = JobManager.get_state()
      assert length(state.job_queue) == 1

      {remaining_job, _} = List.first(state.job_queue)
      assert remaining_job.id == "j2"
    end

    test "does nothing when removing non-existent job" do
      job = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}

      JobManager.add_job(job)
      Process.sleep(10)

      state_before = JobManager.get_state()
      assert length(state_before.job_queue) == 1

      JobManager.remove_job("nonexistent")
      Process.sleep(10)

      state_after = JobManager.get_state()
      assert length(state_after.job_queue) == 1
    end
  end

  describe "assign_jobs/1" do
    test "assigns job to idle villager" do
      # Start a villager
      {:ok, _pid} = VillagerSupervisor.start_villager("v1", "Bob", "p1")
      Process.sleep(10)

      # Add a job
      job = %Job{
        id: "j1",
        type: :gather,
        target: %Resource{type: :wood, location: {5, 5}},
        status: :pending
      }

      JobManager.add_job(job, :high)
      Process.sleep(10)

      # Get villager state
      villager = VillagerServer.get_state("v1")
      villagers = %{"v1" => villager}

      # Assign jobs
      JobManager.assign_jobs(villagers)
      Process.sleep(50)

      # Check that job was assigned
      state = JobManager.get_state()
      assert length(state.job_queue) == 0
      assert Map.has_key?(state.active_jobs, "j1")
      assert state.stats.total_assigned == 1

      # Check villager received the job
      villager_state = VillagerServer.get_state("v1")
      assert villager_state.state == :working
    end

    test "assigns multiple jobs to multiple idle villagers" do
      # Start two villagers
      VillagerSupervisor.start_villager("v1", "Alice", "p1")
      VillagerSupervisor.start_villager("v2", "Bob", "p1")
      Process.sleep(10)

      # Add two jobs
      job1 = %Job{id: "j1", type: :gather, target: %Resource{type: :wood, location: {1, 1}}}
      job2 = %Job{id: "j2", type: :gather, target: %Resource{type: :stone, location: {2, 2}}}

      JobManager.add_job(job1)
      JobManager.add_job(job2)
      Process.sleep(10)

      # Get villager states
      v1 = VillagerServer.get_state("v1")
      v2 = VillagerServer.get_state("v2")
      villagers = %{"v1" => v1, "v2" => v2}

      # Assign jobs
      JobManager.assign_jobs(villagers)
      Process.sleep(50)

      # Check that both jobs were assigned
      state = JobManager.get_state()
      assert length(state.job_queue) == 0
      assert map_size(state.active_jobs) == 2
      assert state.stats.total_assigned == 2
    end

    test "does not assign to working villagers" do
      # Start a villager
      VillagerSupervisor.start_villager("v1", "Charlie", "p1")
      Process.sleep(10)

      # Assign a job directly
      existing_job = %Job{
        id: "j_existing",
        type: :gather,
        target: %Resource{type: :wood, location: {1, 1}}
      }

      VillagerServer.assign_job("v1", existing_job)
      Process.sleep(10)

      # Add another job to queue
      new_job = %Job{id: "j_new", type: :gather, target: %Resource{type: :stone}}
      JobManager.add_job(new_job)
      Process.sleep(10)

      # Get villager state (should be working)
      villager = VillagerServer.get_state("v1")
      assert villager.state == :working

      # Try to assign jobs
      villagers = %{"v1" => villager}
      JobManager.assign_jobs(villagers)
      Process.sleep(50)

      # Job should still be in queue
      state = JobManager.get_state()
      assert length(state.job_queue) == 1
    end

    test "assigns high priority jobs first" do
      # Start villager
      VillagerSupervisor.start_villager("v1", "Dana", "p1")
      Process.sleep(10)

      # Add jobs with different priorities
      job_low = %Job{id: "j_low", type: :gather, target: %Resource{type: :wood}}
      job_high = %Job{id: "j_high", type: :gather, target: %Resource{type: :stone}}

      JobManager.add_job(job_low, :low)
      JobManager.add_job(job_high, :high)
      Process.sleep(10)

      # Assign to villager
      villager = VillagerServer.get_state("v1")
      JobManager.assign_jobs(%{"v1" => villager})
      Process.sleep(50)

      # High priority job should be assigned
      state = JobManager.get_state()
      assert Map.has_key?(state.active_jobs, "j_high")
      assert state.active_jobs["j_high"].job.id == "j_high"

      # Low priority job should still be in queue
      assert length(state.job_queue) == 1
      {queued_job, _} = List.first(state.job_queue)
      assert queued_job.id == "j_low"
    end
  end

  describe "complete_job/2" do
    test "marks job as completed and removes from active jobs" do
      # Start villager and assign job
      VillagerSupervisor.start_villager("v1", "Eve", "p1")
      Process.sleep(10)

      job = %Job{id: "j1", type: :gather, target: %Resource{type: :wood, location: {1, 1}}}
      JobManager.add_job(job)
      Process.sleep(10)

      villager = VillagerServer.get_state("v1")
      JobManager.assign_jobs(%{"v1" => villager})
      Process.sleep(50)

      # Verify job is active
      state_before = JobManager.get_state()
      assert Map.has_key?(state_before.active_jobs, "j1")
      assert state_before.stats.total_completed == 0

      # Complete the job
      JobManager.complete_job("j1", "v1")
      Process.sleep(10)

      # Verify job is no longer active
      state_after = JobManager.get_state()
      refute Map.has_key?(state_after.active_jobs, "j1")
      assert state_after.stats.total_completed == 1
    end
  end

  describe "get_state/0" do
    test "returns current state with queue, active jobs, and stats" do
      state = JobManager.get_state()

      assert is_list(state.job_queue)
      assert is_map(state.active_jobs)
      assert is_map(state.stats)
      assert Map.has_key?(state.stats, :total_assigned)
      assert Map.has_key?(state.stats, :total_completed)
    end
  end

  describe "clear_all_jobs/0" do
    test "clears all jobs from queue and active jobs" do
      # Add some jobs
      job1 = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}
      job2 = %Job{id: "j2", type: :gather, target: %Resource{type: :stone}}

      JobManager.add_job(job1)
      JobManager.add_job(job2)
      Process.sleep(10)

      state_before = JobManager.get_state()
      assert length(state_before.job_queue) == 2

      # Clear all jobs
      JobManager.clear_all_jobs()
      Process.sleep(10)

      state_after = JobManager.get_state()
      assert length(state_after.job_queue) == 0
      assert map_size(state_after.active_jobs) == 0
    end
  end
end
