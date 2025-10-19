defmodule Everstead.Entities.World.Resource do
  @moduledoc """
  Resource entity with type, amount, and optional location.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @resource_types [:wood, :stone, :food]

  @type t :: %__MODULE__{
          type: atom(),
          amount: integer(),
          location: map() | nil
        }

  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: @resource_types
    field :amount, :integer, default: 0
    field :location, :map
  end

  @doc """
  Validates resource attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:type, :amount, :location])
    |> validate_required([:type])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end
end
