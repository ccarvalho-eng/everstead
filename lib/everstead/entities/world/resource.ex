defmodule EverStead.Entities.World.Resource do
  @moduledoc """
  Represents a resource in the game world.

  Resources can exist on tiles or be stored in inventories.
  The location field is optional and only used when the resource
  is placed directly on the world map.
  """
  use TypedStruct

  alias EverStead.Entities.World.Tile

  @typedoc """
  Resource types available in the game.
  """
  @type resource_type :: :wood | :stone | :food

  @typedoc """
  Resource inventory mapping resource types to amounts.
  """
  @type resource_inventory :: %{optional(resource_type()) => integer()}

  typedstruct do
    field :type, resource_type()
    field :amount, integer(), default: 0
    field :location, Tile.coordinate() | nil, default: nil
  end
end
