defmodule EverStead.Entities.World do
  @moduledoc """
  World entity with tile grid and season tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EverStead.Entities.World.Season

  @type t :: %__MODULE__{
          width: integer(),
          height: integer(),
          tiles: map(),
          day: integer(),
          season: Season.t() | nil
        }

  @primary_key false
  embedded_schema do
    field :width, :integer
    field :height, :integer
    field :tiles, :map, default: %{}
    field :day, :integer, default: 0

    embeds_one :season, Season
  end

  @doc """
  Validates world attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(world, attrs) do
    world
    |> cast(attrs, [:width, :height, :tiles, :day])
    |> cast_embed(:season)
    |> validate_required([:width, :height])
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_number(:day, greater_than_or_equal_to: 0)
  end
end
