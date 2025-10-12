defmodule EverStead.Entities.Villager do
  @moduledoc """
  Represents a villager in the game.
  """
  use TypedStruct

  @type state :: :idle | :working | :moving | :resting
  @type job :: :builder | :farmer | :miner
  @type resource_type :: :wood | :stone | :food
  @type inventory :: %{optional(resource_type()) => integer()}

  typedstruct do
    field :id, String.t()
    field :name, String.t()
    field :state, state(), default: :idle
    field :job, job() | nil, default: nil
    field :location, {integer(), integer()}, default: {0, 0}
    field :inventory, inventory(), default: %{}
  end
end
