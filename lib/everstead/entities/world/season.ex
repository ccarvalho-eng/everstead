defmodule EverStead.Entities.World.Season do
  @moduledoc """
  Represents a season in the game world.

  Seasons cycle through Spring, Summer, Fall, and Winter.
  Season progression and effects are handled by the World context.
  """
  use TypedStruct

  alias EverStead.Constants

  typedstruct do
    field :current, Constants.season_type(), default: :spring
    field :ticks_elapsed, integer(), default: 0
    field :year, integer(), default: 1
  end
end
