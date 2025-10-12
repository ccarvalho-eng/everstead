defmodule EverStead.Entities.World do
  @moduledoc """
  Represents the game world.

  The world contains a grid of tiles and tracks time progression
  through days and seasons. Coordinate positions are stored as
  {x, y} tuples.
  """

  use TypedStruct

  alias EverStead.Constants
  alias EverStead.Entities.World.{Season, Tile}

  typedstruct do
    field :width, integer()
    field :height, integer()
    field :tiles, %{Constants.coordinate() => Tile.t()}, default: %{}
    field :day, integer(), default: 0
    field :season, Season.t()
  end
end
