defmodule EverStead.Simulation.PlayerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_player(player_id, name) do
    spec = {EverStead.Simulation.PlayerServer, {player_id, name}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def broadcast_tick do
    for {pid, _} <- Registry.lookup(EverStead.PlayerRegistry, :player) do
      send(pid, :tick)
    end
  end
end
