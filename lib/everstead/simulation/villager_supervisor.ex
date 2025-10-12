defmodule EverStead.Simulation.VillagerSupervisor do
  @moduledoc """
  Dynamic supervisor for managing villager server processes.

  Handles starting and supervising individual villager servers and broadcasting
  tick events to all active villagers for simulation updates.
  """
  use DynamicSupervisor

  @doc """
  Starts the villager supervisor.

  This supervisor is registered with its module name.
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Starts a new villager server process.

  ## Parameters
  - `villager_id` - Unique identifier for the villager
  - `villager_name` - Display name for the villager
  - `player_id` - ID of the player who owns this villager

  ## Examples

      iex> VillagerSupervisor.start_villager("v1", "Bob", "p1")
      {:ok, #PID<0.123.0>}
  """
  @spec start_villager(String.t(), String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_villager(villager_id, villager_name, player_id) do
    spec = {EverStead.Simulation.VillagerServer, {villager_id, villager_name, player_id}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Stops a villager server process.

  ## Parameters
  - `villager_id` - The ID of the villager to stop

  ## Examples

      iex> VillagerSupervisor.stop_villager("v1")
      :ok
  """
  @spec stop_villager(String.t()) :: :ok | {:error, :not_found}
  def stop_villager(villager_id) do
    case Registry.lookup(EverStead.VillagerRegistry, villager_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        :ok

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Broadcasts a tick event to all registered villager servers.

  Looks up all villager processes in the villager registry and sends them
  a `:tick` message to trigger simulation updates.
  """
  @spec broadcast_tick() :: :ok
  def broadcast_tick do
    Registry.select(EverStead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
    |> Enum.each(fn pid -> send(pid, :tick) end)

    :ok
  end

  @doc """
  Lists all active villager IDs.

  ## Examples

      iex> VillagerSupervisor.list_villagers()
      ["v1", "v2", "v3"]
  """
  @spec list_villagers() :: [String.t()]
  def list_villagers do
    Registry.select(EverStead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
  end

  @doc """
  Gets the count of active villagers.

  ## Examples

      iex> VillagerSupervisor.count_villagers()
      5
  """
  @spec count_villagers() :: non_neg_integer()
  def count_villagers do
    Registry.count(EverStead.VillagerRegistry)
  end
end
