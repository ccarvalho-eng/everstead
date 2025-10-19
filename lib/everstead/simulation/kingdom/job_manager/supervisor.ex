defmodule Everstead.Simulation.Kingdom.JobManager.Supervisor do
  @moduledoc """
  Supervisor for job manager processes.
  """
  use Supervisor
  require Logger

  @doc "Starts the job manager supervisor."
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    name =
      if is_tuple(init_arg) and tuple_size(init_arg) == 3 do
        # Custom name provided
        init_arg
      else
        # Default name
        __MODULE__
      end

    Supervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init(init_arg) do
    # Extract kingdom ID from the custom name if provided
    kingdom_id =
      case init_arg do
        {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_sup_" <> kingdom_id}} ->
          kingdom_id

        _ ->
          "default"
      end

    job_manager_name = {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_#{kingdom_id}"}}

    children = [
      {Everstead.Simulation.Kingdom.JobManager.Server, job_manager_name}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Gets the status of all job manager processes."
  @spec status() :: map()
  def status do
    children = Supervisor.which_children(__MODULE__)

    Enum.reduce(children, %{}, fn {id, pid, type, modules}, acc ->
      status = if Process.alive?(pid), do: :running, else: :stopped
      Map.put(acc, id, %{pid: pid, type: type, modules: modules, status: status})
    end)
  end
end
