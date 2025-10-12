defmodule EverStead.Entities.Job do
  @moduledoc """
  Represents a job that can be assigned to a villager.
  """
  use TypedStruct

  alias EverStead.Entities.{Building, Resource, Tile}

  @type type :: :build | :gather | :move
  @type status :: :pending | :in_progress | :done
  @type target :: Tile.t() | Building.t() | Resource.t()

  typedstruct do
    field :id, String.t()
    field :type, type()
    field :target, target()
    field :assigned_villager, String.t() | nil, default: nil
    field :status, status(), default: :pending
  end
end
