defmodule EverStead.Entities.World.Kingdom do
  @moduledoc """
  Represents a player's kingdom.

  A kingdom is a player's domain within the world, containing their
  villagers, buildings, resources, and territory.
  """
  use TypedStruct

  alias EverStead.Constants
  alias EverStead.Entities.World.Kingdom.{Building, Villager}

  typedstruct do
    field :id, String.t()
    field :player_id, String.t()
    field :name, String.t()
    field :villagers, %{String.t() => Villager.t()}, default: %{}
    field :buildings, %{String.t() => Building.t()}, default: %{}
    field :resources, Constants.resource_inventory(), default: %{wood: 0, stone: 0, food: 0}
  end
end
