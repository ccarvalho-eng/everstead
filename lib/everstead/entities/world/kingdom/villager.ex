defmodule EverStead.Entities.World.Kingdom.Villager do
  @moduledoc """
  Represents a villager in the game.

  Villagers can be assigned professions and perform tasks
  like gathering resources, building structures, and farming.
  """
  use TypedStruct

  alias EverStead.Entities.World.Resource
  alias EverStead.Entities.World.Tile

  @typedoc """
  Villager profession types.
  """
  @type profession_type :: :builder | :farmer | :miner

  @type state :: :idle | :working | :moving | :resting

  typedstruct do
    field :id, String.t()
    field :name, String.t()
    field :state, state(), default: :idle
    field :profession, profession_type() | nil, default: nil
    field :location, Tile.coordinate(), default: {0, 0}
    field :inventory, Resource.resource_inventory(), default: %{}
  end
end
