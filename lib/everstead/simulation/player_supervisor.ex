defmodule EverStead.Simulation.PlayerSupervisor do
  @moduledoc """
  Dynamic supervisor for managing player server processes.

  Handles starting and supervising individual player servers and broadcasting
  tick events to all active players for simulation updates.
  """
  use DynamicSupervisor

  @doc """
  Starts the player supervisor.

  This supervisor is registered with its module name.
  """
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  @doc """
  Starts a new player server process.

  ## Parameters
  - `player_id` - Unique identifier for the player
  - `name` - Display name for the player

  ## Examples

      iex> PlayerSupervisor.start_player("p1", "Alice")
      {:ok, #PID<0.123.0>}
  """
  @spec start_player(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_player(player_id, name) do
    spec = {EverStead.Simulation.PlayerServer, {player_id, name}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc """
  Broadcasts a tick event to all registered player servers.

  Iterates through all player processes in the player registry and sends them
  a `:tick` message to trigger simulation updates.
  """
  @spec broadcast_tick() :: :ok
  def broadcast_tick do
    Registry.select(EverStead.PlayerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
    |> Enum.each(fn pid -> send(pid, :tick) end)

    :ok
  end
end
