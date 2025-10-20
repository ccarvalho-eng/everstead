defmodule Everstead.Simulation.Player.Supervisor do
  @moduledoc """
  Supervisor for individual player processes.
  """
  use Supervisor
  require Logger

  @doc "Starts the player supervisor."
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    name = __MODULE__
    Supervisor.start_link(__MODULE__, init_arg, name: name)
  end

  @impl true
  def init({player_id, name, kingdom_name}) do
    kingdom_supervisor_name =
      {:via, Registry, {Everstead.KingdomRegistry, "kingdom_#{player_id}"}}

    children = [
      {Everstead.Simulation.Player.Server, {player_id, name, kingdom_name}},
      {Everstead.Simulation.Kingdom.Supervisor, kingdom_supervisor_name}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Gets the status of all player processes."
  @spec status() :: map()
  def status do
    children = Supervisor.which_children(__MODULE__)

    Enum.reduce(children, %{}, fn {id, pid, type, modules}, acc ->
      status = if Process.alive?(pid), do: :running, else: :stopped
      Map.put(acc, id, %{pid: pid, type: type, modules: modules, status: status})
    end)
  end
end
