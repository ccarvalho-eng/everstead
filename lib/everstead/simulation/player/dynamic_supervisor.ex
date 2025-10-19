defmodule Everstead.Simulation.Player.DynamicSupervisor do
  @moduledoc """
  Dynamic supervisor for managing player supervisor processes.
  """
  use DynamicSupervisor
  require Logger

  @doc "Starts the player dynamic supervisor."
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Starts a new player supervisor process."
  @spec start_player(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
  def start_player(player_id, name) do
    spec = child_spec({player_id, name})
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc "Defines the child spec for a player supervisor."
  @spec child_spec({String.t(), String.t()}) :: Supervisor.child_spec()
  def child_spec({player_id, name}) do
    %{
      id: {__MODULE__, player_id},
      start: {Everstead.Simulation.Player.Supervisor, :start_link, [{player_id, name}]},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
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

  @doc "Broadcasts a tick event to all registered player servers."
  @spec broadcast_tick() :: :ok
  def broadcast_tick do
    try do
      Registry.select(Everstead.PlayerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
      |> Enum.each(fn pid ->
        try do
          send(pid, :tick)
        catch
          error ->
            Logger.warning(
              "Failed to send tick to player process #{inspect(pid)}: #{inspect(error)}"
            )
        end
      end)

      :ok
    catch
      error ->
        Logger.error("Error broadcasting tick to players: #{inspect(error)}")
        :ok
    end
  end
end
