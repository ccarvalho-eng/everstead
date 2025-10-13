defmodule EverStead.Entities.World.Tile do
  @moduledoc """
  Tile entity with terrain, resources, and buildings.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EverStead.Entities.World.Resource

  @terrain_types [:grass, :forest, :water, :mountain]

  @type t :: %__MODULE__{
          terrain: atom(),
          resource: Resource.t() | nil,
          building_id: String.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :terrain, Ecto.Enum, values: @terrain_types, default: :grass
    field :building_id, :string

    embeds_one :resource, Resource
  end

  @doc """
  Validates tile attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(tile, attrs) do
    tile
    |> cast(attrs, [:terrain, :building_id])
    |> cast_embed(:resource)
    |> validate_required([:terrain])
  end
end
