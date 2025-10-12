defmodule EverStead.Entities.Player do
  @moduledoc """
  Represents a player in the game.
  """
  use TypedStruct

  alias EverStead.Entities.{Building, Villager}

  @type resource_type :: :wood | :stone | :food
  @type resources :: %{optional(resource_type()) => integer()}

  typedstruct do
    field :id, String.t()
    field :name, String.t()
    field :villagers, %{String.t() => Villager.t()}, default: %{}
    field :buildings, %{String.t() => Building.t()}, default: %{}
    field :resources, resources(), default: %{wood: 0, stone: 0, food: 0}
  end
end
