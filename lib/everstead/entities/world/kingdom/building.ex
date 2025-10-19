defmodule Everstead.Entities.World.Kingdom.Building do
  @moduledoc """
  Building entity with type, location, and construction status.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @building_types [:house, :farm, :lumberyard, :storage]

  @type t :: %__MODULE__{
          id: binary(),
          type: atom(),
          location: map(),
          construction_progress: integer(),
          hp: integer()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :type, Ecto.Enum, values: @building_types
    field :location, :map
    field :construction_progress, :integer, default: 0
    field :hp, :integer, default: 100
  end

  @doc """
  Validates building attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(building, attrs) do
    building
    |> cast(attrs, [:type, :location, :construction_progress, :hp])
    |> validate_required([:type, :location])
    |> validate_number(:construction_progress, greater_than_or_equal_to: 0)
    |> validate_number(:hp, greater_than_or_equal_to: 0)
  end
end
