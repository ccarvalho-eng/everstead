defmodule EverStead.Entities.Tile do
  @moduledoc """
  Represents a tile on the world map.
  """
  use TypedStruct

  alias EverStead.Entities.Resource

  @type terrain :: :grass | :forest | :water | :mountain

  typedstruct do
    field :terrain, terrain(), default: :grass
    field :resource, Resource.t() | nil, default: nil
    field :building_id, String.t() | nil, default: nil
  end
end
