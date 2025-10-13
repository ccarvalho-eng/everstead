defmodule EverStead.Entities.World.Kingdom do
  @moduledoc """
  Kingdom entity with villagers, buildings, and resources.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EverStead.Entities.World.Kingdom.{Building, Villager}

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          villagers: [Villager.t()],
          buildings: [Building.t()],
          resources: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :resources, :map, default: %{wood: 0, stone: 0, food: 0}

    embeds_many :villagers, Villager
    embeds_many :buildings, Building
  end

  @doc """
  Validates kingdom attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(kingdom, attrs) do
    kingdom
    |> cast(attrs, [:name, :resources])
    |> cast_embed(:villagers)
    |> cast_embed(:buildings)
    |> validate_required([:name])
  end
end
