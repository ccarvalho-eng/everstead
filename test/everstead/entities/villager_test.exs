defmodule Everstead.Entities.VillagerTest do
  use ExUnit.Case, async: true

  alias Everstead.Entities.World.Kingdom.Villager

  test "creates a villager with valid attributes" do
    attributes = %{
      id: "v1",
      name: "John",
      state: :working,
      profession: :builder,
      location: %{x: 3, y: 4},
      inventory: %{wood: 10}
    }

    villager = struct(Villager, attributes)

    assert villager.id == "v1"
    assert villager.name == "John"
    assert villager.state == :working
    assert villager.profession == :builder
    assert villager.location == %{x: 3, y: 4}
    assert villager.inventory == %{wood: 10}
  end

  test "creates a villager with default values" do
    attributes = %{
      id: "v2",
      name: "Jane"
    }

    villager = struct(Villager, attributes)

    assert villager.id == "v2"
    assert villager.name == "Jane"
    assert villager.state == :idle
    assert villager.profession == nil
    assert villager.location == %{x: 0, y: 0}
    assert villager.inventory == %{}
  end
end
