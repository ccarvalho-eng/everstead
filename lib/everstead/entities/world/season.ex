defmodule Everstead.Entities.World.Season do
  @moduledoc """
  Season entity with cycle and year tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @season_types [:spring, :summer, :fall, :winter]

  @type t :: %__MODULE__{
          current: atom(),
          ticks_elapsed: integer(),
          year: integer()
        }

  @primary_key false
  embedded_schema do
    field :current, Ecto.Enum, values: @season_types, default: :spring
    field :ticks_elapsed, :integer, default: 0
    field :year, :integer, default: 1
  end

  @doc """
  Validates season attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(season, attrs) do
    season
    |> cast(attrs, [:current, :ticks_elapsed, :year])
    |> validate_required([:current, :year])
    |> validate_number(:ticks_elapsed, greater_than_or_equal_to: 0)
    |> validate_number(:year, greater_than: 0)
  end
end
