defmodule Everstead.Entities.World.Kingdom.Villager do
  @moduledoc """
  Villager entity with profession, state, and location.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @villager_states [:idle, :working, :moving, :resting]
  @profession_types [:builder, :farmer, :miner]

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          state: atom(),
          profession: atom() | nil,
          location: map(),
          inventory: map()
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :state, Ecto.Enum, values: @villager_states, default: :idle
    field :profession, Ecto.Enum, values: @profession_types
    field :location, :map, default: %{x: 0, y: 0}
    field :inventory, :map, default: %{}
  end

  @doc """
  Validates villager attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(villager, attrs) do
    villager
    |> cast(attrs, [:name, :state, :profession, :location, :inventory])
    |> validate_required([:name])
  end
end
