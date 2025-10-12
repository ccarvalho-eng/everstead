defmodule EverStead.Entities.Player do
  @moduledoc """
  Represents a player in the game.

  Players own a kingdom which contains their villagers, buildings, and resources.
  """
  use TypedStruct

  alias EverStead.Entities.World.Kingdom

  typedstruct do
    field :id, String.t()
    field :name, String.t()
    field :kingdom, Kingdom.t()
  end
end
