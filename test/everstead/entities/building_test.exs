defmodule EverStead.Entities.BuildingTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.Building

  test "creates a building with valid attributes" do
    attributes = %{
      id: "b1",
      type: :house,
      location: {1, 2}
    }

    building = struct(Building, attributes)

    assert building.id == "b1"
    assert building.type == :house
    assert building.location == {1, 2}
    assert building.construction_progress == 0
    assert building.hp == 100
  end
end