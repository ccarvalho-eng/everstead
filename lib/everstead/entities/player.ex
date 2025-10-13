defmodule EverStead.Entities.Player do
  @moduledoc """
  Player entity with kingdom ownership.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias EverStead.Entities.World.Kingdom

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          kingdom: EverStead.Entities.World.Kingdom.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :name, :string
    embeds_one :kingdom, Kingdom
  end

  @doc """
  Validates player attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name])
    |> cast_embed(:kingdom)
    |> validate_required([:name])
  end
end
