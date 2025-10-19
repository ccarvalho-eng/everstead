defmodule Everstead.Simulation.Kingdom.Supervisor do
  @moduledoc """
  Supervisor for kingdom-related processes (JobManager, etc.).
  """
  use Supervisor
  require Logger

  @doc "Starts the kingdom supervisor."
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

    Supervisor.start_link(__MODULE__, name, name: name)
  end

  @impl true
  def init(name) do
    # Extract kingdom ID from the custom name if provided
    kingdom_id =
      case name do
        {:via, Registry, {Everstead.KingdomRegistry, "kingdom_" <> kingdom_id}} -> kingdom_id
        _ -> "default"
      end

    villager_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "villagers_#{kingdom_id}"}}

    job_manager_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_sup_#{kingdom_id}"}}

    children = [
      {Everstead.Simulation.Kingdom.JobManager.Supervisor, job_manager_supervisor_name},
      {Everstead.Simulation.Kingdom.Villager.Supervisor, villager_supervisor_name}
    ]

    # Debug: log the children being started
    Logger.info("Kingdom supervisor starting children: #{inspect(children)}")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Gets the status of all kingdom processes."
  @spec status() :: map()
  def status do
    children = Supervisor.which_children(__MODULE__)

    Enum.reduce(children, %{}, fn {id, pid, type, modules}, acc ->
      status = if Process.alive?(pid), do: :running, else: :stopped
      Map.put(acc, id, %{pid: pid, type: type, modules: modules, status: status})
    end)
  end

  @doc "Restarts a specific kingdom process."
  @spec restart_process(atom()) :: :ok | {:error, :not_found}
  def restart_process(process_id) do
    case Supervisor.restart_child(__MODULE__, process_id) do
      {:ok, _pid} ->
        Logger.info("Successfully restarted #{process_id}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to restart #{process_id}: #{inspect(reason)}")
        {:error, :not_found}
    end
  end
end
