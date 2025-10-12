defmodule EverStead.Simulation.JobManager do
  @moduledoc """
  Manages job assignment and distribution for villagers.

  The JobManager maintains a priority queue of jobs and assigns them to idle
  villagers. It tracks active jobs, handles job completion, and ensures
  efficient resource gathering and building construction.

  ## Job Priority
  Jobs are prioritized as follows:
  1. `:critical` - Building construction, critical resource gathering
  2. `:high` - Important resource gathering
  3. `:normal` - Standard tasks
  4. `:low` - Optional tasks
  """
  use GenServer
  require Logger

  alias EverStead.Entities.Job
  alias EverStead.Simulation.VillagerServer

  @type priority :: :critical | :high | :normal | :low
  @type job_with_priority :: {Job.t(), priority()}

  # Client API

  @doc """
  Starts the job manager server.

  The server is registered with its module name for global access.
  """
  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Adds a job to the queue with a specified priority.

  ## Parameters
  - `job` - The Job struct to add
  - `priority` - Priority level (`:critical`, `:high`, `:normal`, `:low`)

  ## Examples

      iex> job = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}
      iex> JobManager.add_job(job, :high)
      :ok
  """
  @spec add_job(Job.t(), priority()) :: :ok
  def add_job(job, priority \\ :normal) do
    GenServer.cast(__MODULE__, {:add_job, job, priority})
  end

  @doc """
  Removes a job from the queue by ID.

  ## Examples

      iex> JobManager.remove_job("j1")
      :ok
  """
  @spec remove_job(String.t()) :: :ok
  def remove_job(job_id) do
    GenServer.cast(__MODULE__, {:remove_job, job_id})
  end

  @doc """
  Assigns jobs to idle villagers from the job queue.

  Processes a map of villagers and assigns pending jobs to those in idle state.
  Jobs are assigned based on priority.

  ## Parameters
  - `villagers` - Map of villager IDs to villager structs

  ## Examples

      iex> villagers = %{"v1" => %Villager{id: "v1", state: :idle}}
      iex> JobManager.assign_jobs(villagers)
      :ok
  """
  @spec assign_jobs(%{String.t() => Villager.t()}) :: :ok
  def assign_jobs(villagers) do
    GenServer.cast(__MODULE__, {:assign_jobs, villagers})
  end

  @doc """
  Marks a job as completed and removes it from active tracking.

  ## Examples

      iex> JobManager.complete_job("j1", "v1")
      :ok
  """
  @spec complete_job(String.t(), String.t()) :: :ok
  def complete_job(job_id, villager_id) do
    GenServer.cast(__MODULE__, {:complete_job, job_id, villager_id})
  end

  @doc """
  Gets the current state of the job manager including queued and active jobs.

  ## Examples

      iex> JobManager.get_state()
      %{job_queue: [...], active_jobs: %{...}, stats: %{...}}
  """
  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Clears all jobs from the queue and active tracking.
  """
  @spec clear_all_jobs() :: :ok
  def clear_all_jobs do
    GenServer.cast(__MODULE__, :clear_all_jobs)
  end

  @doc """
  Checks for stale jobs where the assigned villager is no longer alive.

  Returns orphaned jobs back to the queue with their original priority.
  This helps recover from villager crashes or unexpected terminations.
  """
  @spec check_stale_jobs() :: :ok
  def check_stale_jobs do
    GenServer.cast(__MODULE__, :check_stale_jobs)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    state = %{
      job_queue: [],
      active_jobs: %{},
      stats: %{
        total_assigned: 0,
        total_completed: 0
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_job, job, priority}, state) do
    job_with_priority = {job, priority}
    new_queue = insert_by_priority(state.job_queue, job_with_priority)

    Logger.info("Added job #{job.id} with priority #{priority} to queue")

    {:noreply, %{state | job_queue: new_queue}}
  end

  @impl true
  def handle_cast({:remove_job, job_id}, state) do
    new_queue = Enum.reject(state.job_queue, fn {job, _priority} -> job.id == job_id end)

    Logger.info("Removed job #{job_id} from queue")

    {:noreply, %{state | job_queue: new_queue}}
  end

  @impl true
  def handle_cast({:assign_jobs, villagers}, state) do
    idle_villagers =
      villagers
      |> Enum.filter(fn {_id, villager} -> villager.state == :idle end)
      |> Enum.map(fn {id, _villager} -> id end)

    {new_state, _assigned_count} =
      Enum.reduce(idle_villagers, {state, 0}, fn villager_id, {current_state, count} ->
        case assign_next_job(current_state, villager_id) do
          {:ok, updated_state} -> {updated_state, count + 1}
          {:error, :no_jobs} -> {current_state, count}
        end
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:complete_job, job_id, villager_id}, state) do
    new_active_jobs = Map.delete(state.active_jobs, job_id)
    new_stats = %{state.stats | total_completed: state.stats.total_completed + 1}

    Logger.info("Job #{job_id} completed by villager #{villager_id}")

    {:noreply, %{state | active_jobs: new_active_jobs, stats: new_stats}}
  end

  @impl true
  def handle_cast(:clear_all_jobs, state) do
    Logger.info("Clearing all jobs from JobManager")

    new_state = %{
      state
      | job_queue: [],
        active_jobs: %{},
        stats: %{total_assigned: 0, total_completed: 0}
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:check_stale_jobs, state) do
    Logger.debug("Checking for stale jobs...")

    {stale_jobs, valid_jobs} =
      Enum.split_with(state.active_jobs, fn {_job_id, job_info} ->
        case Registry.lookup(EverStead.VillagerRegistry, job_info.villager_id) do
          [] -> true
          [{_pid, _}] -> false
        end
      end)

    if length(stale_jobs) > 0 do
      Logger.warning("Found #{length(stale_jobs)} stale jobs, returning to queue")

      # Return stale jobs to queue with original priority
      new_queue =
        Enum.reduce(stale_jobs, state.job_queue, fn {_job_id, job_info}, queue ->
          insert_by_priority(queue, {job_info.job, job_info.priority})
        end)

      new_state = %{
        state
        | job_queue: new_queue,
          active_jobs: Map.new(valid_jobs)
      }

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Private Functions

  @spec insert_by_priority([job_with_priority()], job_with_priority()) :: [job_with_priority()]
  defp insert_by_priority(queue, {_job, priority} = new_item) do
    priority_order = %{critical: 0, high: 1, normal: 2, low: 3}
    new_priority_value = priority_order[priority]

    {before, after_list} =
      Enum.split_while(queue, fn {_j, p} ->
        priority_order[p] <= new_priority_value
      end)

    before ++ [new_item] ++ after_list
  end

  @spec assign_next_job(map(), String.t()) :: {:ok, map()} | {:error, :no_jobs}
  defp assign_next_job(%{job_queue: []} = _state, _villager_id) do
    {:error, :no_jobs}
  end

  defp assign_next_job(state, villager_id) do
    [{job, priority} | rest_queue] = state.job_queue

    # Check if villager still exists before assigning
    case Registry.lookup(EverStead.VillagerRegistry, villager_id) do
      [] ->
        Logger.warning("Villager #{villager_id} not found, skipping job assignment")
        {:error, :no_jobs}

      [{_pid, _}] ->
        # Assign job to villager
        case VillagerServer.assign_job(villager_id, job) do
          :ok ->
            new_active_jobs =
              Map.put(state.active_jobs, job.id, %{
                job: job,
                villager_id: villager_id,
                assigned_at: System.system_time(:second),
                priority: priority
              })

            new_stats = %{state.stats | total_assigned: state.stats.total_assigned + 1}

            Logger.info("Assigned job #{job.id} (#{job.type}) to villager #{villager_id}")

            new_state = %{
              state
              | job_queue: rest_queue,
                active_jobs: new_active_jobs,
                stats: new_stats
            }

            {:ok, new_state}

          {:error, reason} ->
            # Job assignment failed - put job back at front of queue with retry
            Logger.warning(
              "Failed to assign job #{job.id} to villager #{villager_id}: #{inspect(reason)}"
            )

            {:error, :no_jobs}
        end
    end
  end
end
