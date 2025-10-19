defmodule Everstead.Simulation.World.Supervisor do
  @moduledoc """
  Supervisor for world-related processes.
  """
  use Supervisor
  require Logger

  @doc "Starts the world supervisor."
  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Everstead.Simulation.World.Server,
      {Everstead.Simulation.Player.DynamicSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 10)
  end

  @doc "Gets the status of all world processes."
  @spec status() :: map()
  def status do
    children = Supervisor.which_children(__MODULE__)

    Enum.reduce(children, %{}, fn {id, pid, type, modules}, acc ->
      status = if Process.alive?(pid), do: :running, else: :stopped
      Map.put(acc, id, %{pid: pid, type: type, modules: modules, status: status})
    end)
  end
end
