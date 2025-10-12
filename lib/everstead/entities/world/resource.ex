defmodule EverStead.Entities.World.Resource do
  @moduledoc """
  Represents a resource in the game world.

  Resources can exist on tiles or be stored in inventories.
  The location field is optional and only used when the resource
  is placed directly on the world map.
  """
  use TypedStruct

  alias EverStead.Entities.Types

  typedstruct do
    field :type, Types.resource_type()
    field :amount, integer(), default: 0
    field :location, Types.coordinate() | nil, default: nil
  end
end
