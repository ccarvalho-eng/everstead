defmodule EverStead.Entities.Building do
  @moduledoc """
  Represents a building in the game world.
  """
  use TypedStruct

  @type type :: :house | :farm | :lumberyard | :storage

  typedstruct do
    field :id, String.t()
    field :type, type()
    field :location, {integer(), integer()}
    field :construction_progress, integer(), default: 0
    field :hp, integer(), default: 100
  end
end
