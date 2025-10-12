defmodule EverStead.Entities.PlayerTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.Player

  test "creates a player with valid attributes" do
    attributes = %{
      id: "p1",
      name: "Cristiano"
    }

    player = struct(Player, attributes)

    assert player.id == "p1"
    assert player.name == "Cristiano"
    assert player.villagers == %{}
    assert player.buildings == %{}
    assert player.resources == %{wood: 0, stone: 0, food: 0}
  end
end