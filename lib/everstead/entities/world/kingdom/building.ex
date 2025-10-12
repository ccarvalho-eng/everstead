defmodule EverStead.Entities.World.Kingdom.Building do
  @moduledoc """
  Represents a building in the game world.

  Buildings are placed on tiles and can have various functions
  like housing villagers, producing resources, or storing items.
  """
  use TypedStruct

  alias EverStead.Constants

  @type type :: :house | :farm | :lumberyard | :storage

  typedstruct do
    field :id, String.t()
    field :type, type()
    field :location, Constants.coordinate()
    field :construction_progress, integer(), default: 0
    field :hp, integer(), default: 100
  end
end
