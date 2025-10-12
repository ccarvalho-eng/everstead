defmodule EverStead.Entities.World.Kingdom.Job do
  @moduledoc """
  Represents a task that can be assigned to a villager.

  Jobs are tasks like building structures, gathering resources,
  or moving items. They track progress and which villager is assigned.
  """
  use TypedStruct

  alias EverStead.Entities.World.{Resource, Tile}
  alias EverStead.Entities.World.Kingdom.Building

  @type type :: :build | :gather | :move
  @type status :: :pending | :in_progress | :done
  @type target :: Tile.t() | Building.t() | Resource.t()

  typedstruct do
    field :id, String.t()
    field :type, type()
    field :target, target()
    field :assigned_villager_id, String.t() | nil, default: nil
    field :status, status(), default: :pending
  end
end
