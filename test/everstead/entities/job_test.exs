defmodule EverStead.Entities.JobTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.World.Kingdom.Job
  alias EverStead.Entities.World.Tile

  test "creates a job with valid attributes" do
    tile = struct(Tile, %{terrain: :grass})

    attributes = %{
      id: "j1",
      type: :build,
      target: tile
    }

    job = struct(Job, attributes)

    assert job.id == "j1"
    assert job.type == :build
    assert job.target == tile
    assert job.assigned_villager_id == nil
    assert job.status == :pending
  end
end
