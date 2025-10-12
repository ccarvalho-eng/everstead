defmodule EverStead.Entities.World.Kingdom.Villager do
  @moduledoc """
  Represents a villager in the game.

  Villagers can be assigned professions and perform tasks
  like gathering resources, building structures, and farming.
  """
  use TypedStruct

  alias EverStead.Entities.Types

  @type state :: :idle | :working | :moving | :resting

  typedstruct do
    field :id, String.t()
    field :name, String.t()
    field :state, state(), default: :idle
    field :profession, Types.profession_type() | nil, default: nil
    field :location, Types.coordinate(), default: {0, 0}
    field :inventory, Types.resource_inventory(), default: %{}
  end
end
