defmodule EverStead.Entities.SeasonTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.World.Season
  alias EverStead.World

  describe "season_duration/0" do
    test "returns the configured season duration" do
      assert World.season_duration() == 60
    end
  end

  describe "next_season/1" do
    test "returns summer after spring" do
      assert World.next_season(:spring) == :summer
    end

    test "returns fall after summer" do
      assert World.next_season(:summer) == :fall
    end

    test "returns winter after fall" do
      assert World.next_season(:fall) == :winter
    end

    test "returns spring after winter (cycles back)" do
      assert World.next_season(:winter) == :spring
    end
  end

  describe "tick_season/1" do
    test "increments ticks_elapsed by 1" do
      season = %Season{current: :spring, ticks_elapsed: 10, year: 1}
      updated = World.tick_season(season)

      assert updated.ticks_elapsed == 11
      assert updated.current == :spring
      assert updated.year == 1
    end

    test "progresses to next season when duration is reached" do
      season = %Season{current: :spring, ticks_elapsed: 59, year: 1}
      updated = World.tick_season(season)

      assert updated.current == :summer
      assert updated.ticks_elapsed == 0
      assert updated.year == 1
    end

    test "increments year when winter transitions to spring" do
      season = %Season{current: :winter, ticks_elapsed: 59, year: 1}
      updated = World.tick_season(season)

      assert updated.current == :spring
      assert updated.ticks_elapsed == 0
      assert updated.year == 2
    end

    test "progresses through all seasons correctly" do
      season = %Season{current: :spring, ticks_elapsed: 0, year: 1}

      # Advance through spring
      season = Enum.reduce(1..60, season, fn _, s -> World.tick_season(s) end)
      assert season.current == :summer
      assert season.ticks_elapsed == 0

      # Advance through summer
      season = Enum.reduce(1..60, season, fn _, s -> World.tick_season(s) end)
      assert season.current == :fall
      assert season.ticks_elapsed == 0

      # Advance through fall
      season = Enum.reduce(1..60, season, fn _, s -> World.tick_season(s) end)
      assert season.current == :winter
      assert season.ticks_elapsed == 0

      # Advance through winter - should go to year 2
      season = Enum.reduce(1..60, season, fn _, s -> World.tick_season(s) end)
      assert season.current == :spring
      assert season.ticks_elapsed == 0
      assert season.year == 2
    end
  end

  describe "resource_multiplier/1" do
    test "returns 1.0 for spring" do
      assert World.resource_multiplier(:spring) == 1.0
    end

    test "returns 1.2 for summer" do
      assert World.resource_multiplier(:summer) == 1.2
    end

    test "returns 1.1 for fall" do
      assert World.resource_multiplier(:fall) == 1.1
    end

    test "returns 0.7 for winter" do
      assert World.resource_multiplier(:winter) == 0.7
    end
  end

  describe "farming_multiplier/1" do
    test "returns 1.3 for spring (planting season)" do
      assert World.farming_multiplier(:spring) == 1.3
    end

    test "returns 1.5 for summer (growing season)" do
      assert World.farming_multiplier(:summer) == 1.5
    end

    test "returns 1.2 for fall (harvest season)" do
      assert World.farming_multiplier(:fall) == 1.2
    end

    test "returns 0.3 for winter (harsh conditions)" do
      assert World.farming_multiplier(:winter) == 0.3
    end
  end

  describe "construction_multiplier/1" do
    test "returns 1.1 for spring" do
      assert World.construction_multiplier(:spring) == 1.1
    end

    test "returns 1.2 for summer (ideal conditions)" do
      assert World.construction_multiplier(:summer) == 1.2
    end

    test "returns 1.0 for fall" do
      assert World.construction_multiplier(:fall) == 1.0
    end

    test "returns 0.6 for winter (harsh conditions)" do
      assert World.construction_multiplier(:winter) == 0.6
    end
  end

  describe "season_to_string/1" do
    test "returns capitalized season names" do
      assert World.season_to_string(:spring) == "Spring"
      assert World.season_to_string(:summer) == "Summer"
      assert World.season_to_string(:fall) == "Fall"
      assert World.season_to_string(:winter) == "Winter"
    end
  end

  describe "struct creation" do
    test "creates season with default values" do
      season = %Season{}

      assert season.current == :spring
      assert season.ticks_elapsed == 0
      assert season.year == 1
    end

    test "creates season with custom values" do
      season = %Season{current: :winter, ticks_elapsed: 30, year: 5}

      assert season.current == :winter
      assert season.ticks_elapsed == 30
      assert season.year == 5
    end
  end
end
