defmodule EverStead.Entities.World.Tile do
  @moduledoc """
  Represents a tile on the world map.

  Each tile has a terrain type and can optionally contain a resource
  or have a building placed on it.
  """
  use TypedStruct

  alias EverStead.Entities.World.Resource

  @typedoc """
  Coordinate tuple representing a position on the world map.
  """
  @type coordinate :: {integer(), integer()}

  @type terrain :: :grass | :forest | :water | :mountain

  typedstruct do
    field :terrain, terrain(), default: :grass
    field :resource, Resource.t() | nil, default: nil
    field :building_id, String.t() | nil, default: nil
  end
end
