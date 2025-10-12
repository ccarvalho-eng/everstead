defmodule EverStead.Entities.TileTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.Tile
  alias EverStead.Entities.Resource

  test "creates a tile with valid attributes" do
    resource = struct(Resource, %{type: :wood, amount: 100})

    attributes = %{
      terrain: :forest,
      resource: resource,
      building_id: "b1"
    }

    tile = struct(Tile, attributes)

    assert tile.terrain == :forest
    assert tile.resource == resource
    assert tile.building_id == "b1"
  end

  test "creates a tile with default values" do
    tile = struct(Tile)

    assert tile.terrain == :grass
    assert tile.resource == nil
    assert tile.building_id == nil
  end
end
