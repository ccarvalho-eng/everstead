defmodule EverStead.Entities.PlayerTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.Player
  alias EverStead.Entities.World.Kingdom

  test "creates a player with valid attributes" do
    kingdom = %Kingdom{
      id: "k1",
      player_id: "p1",
      name: "Test Kingdom"
    }

    attributes = %{
      id: "p1",
      name: "Cristiano",
      kingdom: kingdom
    }

    player = struct(Player, attributes)

    assert player.id == "p1"
    assert player.name == "Cristiano"
    assert player.kingdom.id == "k1"
    assert player.kingdom.villagers == %{}
    assert player.kingdom.buildings == %{}
    assert player.kingdom.resources == %{wood: 0, stone: 0, food: 0}
  end
end
