defmodule EverStead.Entities.WorldTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.World
  alias EverStead.Entities.World.{Season, Tile}

  test "creates a world with valid attributes" do
    tile = struct(Tile)
    season = %Season{current: :summer}

    attributes = %{
      width: 100,
      height: 100,
      tiles: %{{0, 0} => tile},
      day: 1,
      season: season
    }

    world = struct(World, attributes)

    assert world.width == 100
    assert world.height == 100
    assert world.tiles == %{{0, 0} => tile}
    assert world.day == 1
    assert world.season == season
  end

  test "creates a world with default values" do
    attributes = %{
      width: 50,
      height: 50
    }

    world = struct(World, attributes)

    assert world.width == 50
    assert world.height == 50
    assert world.tiles == %{}
    assert world.day == 0
    assert world.season == nil
  end
end
