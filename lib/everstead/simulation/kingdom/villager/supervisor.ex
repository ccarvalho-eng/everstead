defmodule Everstead.Simulation.Kingdom.Villager.Supervisor do
  @moduledoc """
  Dynamic supervisor for managing villager server processes.
  """
  use DynamicSupervisor
  require Logger

  @doc "Starts the villager supervisor."
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    name =
      case init_arg do
        {{:via, Registry, {Everstead.KingdomRegistry, "villagers_" <> _kingdom_id}} = custom_name,
         :ok} ->
          custom_name

        {:via, Registry, {Everstead.KingdomRegistry, "villagers_" <> _kingdom_id}} = custom_name ->
          custom_name

        _ ->
          __MODULE__
      end

    DynamicSupervisor.start_link(__MODULE__, :ok, name: name)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Starts a new villager server process."
  @spec start_villager(String.t(), String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_villager(villager_id, villager_name, player_id) do
    # Find the correct villager supervisor for this player's kingdom
    villager_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "villagers_#{player_id}"}}

    spec = child_spec({villager_id, villager_name, player_id})
    DynamicSupervisor.start_child(villager_supervisor_name, spec)
  end

  @doc "Defines the child spec for a villager server."
  @spec child_spec({String.t(), String.t(), String.t()}) :: Supervisor.child_spec()
  def child_spec({villager_id, villager_name, player_id}) do
    %{
      id: {__MODULE__, villager_id},
      start:
        {Everstead.Simulation.Kingdom.Villager.Server, :start_link,
         [{villager_id, villager_name, player_id}]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }
  end

  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      restart: :permanent,
      type: :supervisor
    }
  end

  @doc "Broadcasts a tick event to all registered villager servers."
  @spec broadcast_tick() :: :ok
  def broadcast_tick do
    try do
      # Get all villagers directly from the VillagerRegistry
      Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
      |> Enum.each(fn villager_pid ->
        try do
          send(villager_pid, :tick)
        catch
          error ->
            Logger.warning(
              "Failed to send tick to villager process #{inspect(villager_pid)}: #{inspect(error)}"
            )
        end
      end)

      :ok
    catch
      error ->
        Logger.error("Error broadcasting tick to villagers: #{inspect(error)}")
        :ok
    end
  end

  @doc "Stops a villager server process."
  @spec stop_villager(String.t()) :: :ok | {:error, :not_found}
  def stop_villager(villager_id) do
    case Registry.lookup(Everstead.VillagerRegistry, villager_id) do
      [{pid, _}] ->
        # Find the supervisor that manages this villager
        supervisors = get_villager_supervisors()

        case Enum.find(supervisors, fn supervisor_name ->
               case DynamicSupervisor.terminate_child(supervisor_name, pid) do
                 :ok -> true
                 _ -> false
               end
             end) do
          nil ->
            # If we can't find the supervisor, just kill the process
            # This is acceptable for testing purposes
            Process.exit(pid, :kill)
            :ok

          _ ->
            :ok
        end

      [] ->
        {:error, :not_found}
    end
  end

  # Helper function to get all villager supervisor names
  defp get_villager_supervisors do
    # Get all entries and filter for villager supervisors
    all_entries =
      Registry.select(Everstead.KingdomRegistry, [
        {{:"$1", :"$2", :"$3"}, [], [:"$1", :"$2", :"$3"]}
      ])

    all_entries
    |> Enum.filter(fn entry ->
      case entry do
        {key, _pid, _value} when is_binary(key) -> String.starts_with?(key, "villagers_")
        _ -> false
      end
    end)
    |> Enum.map(fn {_key, pid, _value} -> pid end)
  end

  @doc "Lists all active villager IDs."
  @spec list_villagers() :: [String.t()]
  def list_villagers do
    Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
  end

  @doc "Gets the count of active villagers."
  @spec count_villagers() :: non_neg_integer()
  def count_villagers do
    Registry.count(Everstead.VillagerRegistry)
  end
end
