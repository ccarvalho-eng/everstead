defmodule EverStead.Entities.World.Season do
  @moduledoc """
  Represents a season in the game world.

  Seasons cycle through Spring, Summer, Fall, and Winter.
  Season progression and effects are handled by the World context.
  """
  use TypedStruct

  @typedoc """
  Season types in the game world.
  Seasons cycle through: spring -> summer -> fall -> winter -> spring
  """
  @type season_type :: :spring | :summer | :fall | :winter

  typedstruct do
    field :current, season_type(), default: :spring
    field :ticks_elapsed, integer(), default: 0
    field :year, integer(), default: 1
  end
end
