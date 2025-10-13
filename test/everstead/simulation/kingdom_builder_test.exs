defmodule EverStead.Simulation.KingdomBuilderTest do
  use ExUnit.Case, async: true

  alias EverStead.Simulation.KingdomBuilder
  alias EverStead.Entities.Player
  alias EverStead.Entities.World.Kingdom
  alias EverStead.Entities.World.Kingdom.Building
  alias EverStead.Entities.World.Tile

  defp create_player(resources) do
    kingdom = %Kingdom{
      id: "k1",
      name: "Test Kingdom",
      villagers: [],
      buildings: [],
      resources: resources
    }

    %Player{
      id: "p1",
      name: "Test Player",
      kingdom: kingdom
    }
  end

  describe "place_building/4" do
    test "successfully places a building with sufficient resources" do
      player = create_player(%{wood: 100, stone: 50, food: 10})
      tile = %Tile{terrain: :grass, building_id: nil}

      assert {:ok, {updated_player, building}} =
               KingdomBuilder.place_building(player, tile, :house, {5, 5})

      assert building.type == :house
      assert building.location == {5, 5}
      assert building.construction_progress == 0
      assert building.hp == 100
      assert is_binary(building.id)

      # Verify resources were deducted (house costs: wood: 50, stone: 20)
      assert updated_player.kingdom.resources.wood == 50
      assert updated_player.kingdom.resources.stone == 30
      assert updated_player.kingdom.resources.food == 10

      # Verify building was added to player's kingdom
      assert Enum.any?(updated_player.kingdom.buildings, fn b -> b.id == building.id end)
    end

    test "fails when resources are insufficient" do
      player = create_player(%{wood: 10, stone: 5, food: 0})
      tile = %Tile{terrain: :grass, building_id: nil}

      assert {:error, :insufficient_resources} =
               KingdomBuilder.place_building(player, tile, :house, {5, 5})
    end

    test "fails when terrain is water" do
      player = create_player(%{wood: 100, stone: 50, food: 10})
      tile = %Tile{terrain: :water, building_id: nil}

      assert {:error, :invalid_terrain} =
               KingdomBuilder.place_building(player, tile, :house, {5, 5})
    end

    test "fails when terrain is mountain" do
      player = create_player(%{wood: 100, stone: 50, food: 10})
      tile = %Tile{terrain: :mountain, building_id: nil}

      assert {:error, :invalid_terrain} =
               KingdomBuilder.place_building(player, tile, :house, {5, 5})
    end

    test "fails when tile is occupied" do
      player = create_player(%{wood: 100, stone: 50, food: 10})
      tile = %Tile{terrain: :grass, building_id: "existing_building"}

      assert {:error, :tile_occupied} =
               KingdomBuilder.place_building(player, tile, :house, {5, 5})
    end

    test "successfully places different building types" do
      player = create_player(%{wood: 200, stone: 100, food: 50})
      tile = %Tile{terrain: :grass, building_id: nil}

      # Test farm
      assert {:ok, {updated_player, farm}} =
               KingdomBuilder.place_building(player, tile, :farm, {1, 1})

      assert farm.type == :farm
      assert updated_player.kingdom.resources.wood == 170
      assert updated_player.kingdom.resources.stone == 90

      # Test lumberyard
      assert {:ok, {updated_player2, lumberyard}} =
               KingdomBuilder.place_building(updated_player, tile, :lumberyard, {2, 2})

      assert lumberyard.type == :lumberyard
      assert updated_player2.kingdom.resources.wood == 130
      assert updated_player2.kingdom.resources.stone == 60

      # Test storage
      assert {:ok, {updated_player3, storage}} =
               KingdomBuilder.place_building(updated_player2, tile, :storage, {3, 3})

      assert storage.type == :storage
      assert updated_player3.kingdom.resources.wood == 70
      assert updated_player3.kingdom.resources.stone == 20
    end
  end

  describe "advance_construction/2" do
    test "advances construction progress by building's rate" do
      building = %Building{
        id: "b1",
        type: :house,
        location: {5, 5},
        construction_progress: 0
      }

      # House has construction rate of 10
      updated = KingdomBuilder.advance_construction(building)
      assert updated.construction_progress == 10

      updated2 = KingdomBuilder.advance_construction(updated)
      assert updated2.construction_progress == 20
    end

    test "advances construction by multiple ticks" do
      building = %Building{
        id: "b1",
        type: :house,
        location: {5, 5},
        construction_progress: 0
      }

      updated = KingdomBuilder.advance_construction(building, 5)
      assert updated.construction_progress == 50
    end

    test "caps construction progress at 100" do
      building = %Building{
        id: "b1",
        type: :house,
        location: {5, 5},
        construction_progress: 95
      }

      updated = KingdomBuilder.advance_construction(building)
      assert updated.construction_progress == 100

      # Advancing again should stay at 100
      updated2 = KingdomBuilder.advance_construction(updated)
      assert updated2.construction_progress == 100
    end

    test "different building types have different construction rates" do
      house = %Building{id: "b1", type: :house, construction_progress: 0}
      farm = %Building{id: "b2", type: :farm, construction_progress: 0}
      lumberyard = %Building{id: "b3", type: :lumberyard, construction_progress: 0}
      storage = %Building{id: "b4", type: :storage, construction_progress: 0}

      assert KingdomBuilder.advance_construction(house).construction_progress == 10
      assert KingdomBuilder.advance_construction(farm).construction_progress == 8
      assert KingdomBuilder.advance_construction(lumberyard).construction_progress == 12
      assert KingdomBuilder.advance_construction(storage).construction_progress == 15
    end
  end

  describe "advance_construction_with_season/3" do
    test "applies summer bonus (20% faster)" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 0
      }

      # House base rate: 10, Summer multiplier: 1.2, Result: floor(10 * 1.2) = 12
      updated = KingdomBuilder.advance_construction_with_season(building, :summer, 1)
      assert updated.construction_progress == 12
    end

    test "applies spring bonus (10% faster)" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 0
      }

      # House base rate: 10, Spring multiplier: 1.1, Result: floor(10 * 1.1) = 11
      updated = KingdomBuilder.advance_construction_with_season(building, :spring, 1)
      assert updated.construction_progress == 11
    end

    test "applies fall normal speed" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 0
      }

      # House base rate: 10, Fall multiplier: 1.0, Result: 10
      updated = KingdomBuilder.advance_construction_with_season(building, :fall, 1)
      assert updated.construction_progress == 10
    end

    test "applies winter penalty (40% slower)" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 0
      }

      # House base rate: 10, Winter multiplier: 0.6, Result: floor(10 * 0.6) = 6
      updated = KingdomBuilder.advance_construction_with_season(building, :winter, 1)
      assert updated.construction_progress == 6
    end

    test "works with multiple ticks" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 0
      }

      # House base rate: 10, Summer multiplier: 1.2, Result: floor(10 * 1.2) * 5 = 60
      updated = KingdomBuilder.advance_construction_with_season(building, :summer, 5)
      assert updated.construction_progress == 60
    end

    test "caps at 100 even with season bonuses" do
      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 95
      }

      # Would be 95 + 12 = 107, but caps at 100
      updated = KingdomBuilder.advance_construction_with_season(building, :summer, 1)
      assert updated.construction_progress == 100
    end

    test "applies seasons to different building types" do
      # Farm base rate: 8
      farm = %Building{id: "b1", type: :farm, construction_progress: 0}
      # 8 * 1.2 = 9.6, floor = 9
      assert KingdomBuilder.advance_construction_with_season(farm, :summer).construction_progress ==
               9

      # Lumberyard base rate: 12
      lumberyard = %Building{id: "b2", type: :lumberyard, construction_progress: 0}
      # 12 * 0.6 = 7.2, floor = 7
      assert KingdomBuilder.advance_construction_with_season(lumberyard, :winter).construction_progress ==
               7

      # Storage base rate: 15
      storage = %Building{id: "b3", type: :storage, construction_progress: 0}
      # 15 * 1.1 = 16.5, floor = 16
      assert KingdomBuilder.advance_construction_with_season(storage, :spring).construction_progress ==
               16
    end
  end

  describe "construction_complete?/1" do
    test "returns true when construction is 100%" do
      building = %Building{construction_progress: 100}
      assert KingdomBuilder.construction_complete?(building) == true
    end

    test "returns false when construction is less than 100%" do
      building = %Building{construction_progress: 99}
      assert KingdomBuilder.construction_complete?(building) == false

      building2 = %Building{construction_progress: 0}
      assert KingdomBuilder.construction_complete?(building2) == false
    end
  end

  describe "cancel_construction/2" do
    test "refunds 50% of resources when construction is less than 50% complete" do
      kingdom = %Kingdom{
        id: "k1",
        name: "Test Kingdom",
        resources: %{wood: 10, stone: 5, food: 0},
        buildings: [%Building{id: "b1", type: :house, location: %{}, construction_progress: 0}]
      }

      player = %Player{id: "p1", name: "Test Player", kingdom: kingdom}

      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 30
      }

      {:ok, updated_player} = KingdomBuilder.cancel_construction(player, building)

      # House costs: wood: 50, stone: 20
      # 50% refund: wood: 25, stone: 10
      assert updated_player.kingdom.resources.wood == 35
      assert updated_player.kingdom.resources.stone == 15
      assert updated_player.kingdom.resources.food == 0

      # Building should be removed from player's kingdom
      refute Enum.any?(updated_player.kingdom.buildings, fn b -> b.id == "b1" end)
    end

    test "refunds nothing when construction is 50% or more complete" do
      kingdom = %Kingdom{
        id: "k1",
        name: "Test Kingdom",
        resources: %{wood: 10, stone: 5, food: 0},
        buildings: [%Building{id: "b1", type: :house, location: %{}, construction_progress: 0}]
      }

      player = %Player{id: "p1", name: "Test Player", kingdom: kingdom}

      building = %Building{
        id: "b1",
        type: :house,
        construction_progress: 50
      }

      {:ok, updated_player} = KingdomBuilder.cancel_construction(player, building)

      # No refund
      assert updated_player.kingdom.resources.wood == 10
      assert updated_player.kingdom.resources.stone == 5

      # Building should still be removed
      refute Enum.any?(updated_player.kingdom.buildings, fn b -> b.id == "b1" end)
    end
  end

  describe "can_build_at?/2" do
    test "returns :ok when tile is valid" do
      tile = %Tile{terrain: :grass, building_id: nil}
      assert :ok = KingdomBuilder.can_build_at?(tile, :house)
    end

    test "returns error when terrain is invalid" do
      water_tile = %Tile{terrain: :water, building_id: nil}
      assert {:error, :invalid_terrain} = KingdomBuilder.can_build_at?(water_tile, :house)

      mountain_tile = %Tile{terrain: :mountain, building_id: nil}
      assert {:error, :invalid_terrain} = KingdomBuilder.can_build_at?(mountain_tile, :house)
    end

    test "returns error when tile is occupied" do
      tile = %Tile{terrain: :grass, building_id: "existing"}
      assert {:error, :tile_occupied} = KingdomBuilder.can_build_at?(tile, :house)
    end

    test "returns error for invalid building type" do
      tile = %Tile{terrain: :grass, building_id: nil}
      assert {:error, :invalid_building_type} = KingdomBuilder.can_build_at?(tile, :castle)
    end
  end

  describe "get_building_cost/1" do
    test "returns correct costs for each building type" do
      assert KingdomBuilder.get_building_cost(:house) == %{wood: 50, stone: 20, food: 0}
      assert KingdomBuilder.get_building_cost(:farm) == %{wood: 30, stone: 10, food: 0}
      assert KingdomBuilder.get_building_cost(:lumberyard) == %{wood: 40, stone: 30, food: 0}
      assert KingdomBuilder.get_building_cost(:storage) == %{wood: 60, stone: 40, food: 0}
    end

    test "returns zero cost for unknown building type" do
      assert KingdomBuilder.get_building_cost(:unknown) == %{wood: 0, stone: 0, food: 0}
    end
  end

  describe "get_construction_rate/1" do
    test "returns correct construction rates" do
      assert KingdomBuilder.get_construction_rate(:house) == 10
      assert KingdomBuilder.get_construction_rate(:farm) == 8
      assert KingdomBuilder.get_construction_rate(:lumberyard) == 12
      assert KingdomBuilder.get_construction_rate(:storage) == 15
    end

    test "returns default rate for unknown building type" do
      assert KingdomBuilder.get_construction_rate(:unknown) == 10
    end
  end
end
