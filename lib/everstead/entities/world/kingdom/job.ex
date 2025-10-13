defmodule EverStead.Entities.World.Kingdom.Job do
  @moduledoc """
  Job entity with type, target, and assigned villager.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @job_types [:build, :gather, :move]
  @job_statuses [:pending, :in_progress, :done]

  @type t :: %__MODULE__{
          id: binary(),
          type: atom(),
          status: atom(),
          target: map(),
          assigned_villager_id: String.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :type, Ecto.Enum, values: @job_types
    field :status, Ecto.Enum, values: @job_statuses, default: :pending
    field :target, :map
    field :assigned_villager_id, :string
  end

  @doc """
  Validates job attributes.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:type, :status, :target, :assigned_villager_id])
    |> validate_required([:type, :target])
  end
end
