defmodule EverStead.Entities.World do
  @moduledoc """
  Represents the game world.
  """

  use TypedStruct

  alias EverStead.Entities.Tile

  @type season :: :spring | :summer | :autumn | :winter

  typedstruct do
    field :width, integer()
    field :height, integer()
    field :tiles, %{{integer(), integer()} => Tile.t()}, default: %{}
    field :day, integer(), default: 0
    field :season, season(), default: :spring
  end
end
