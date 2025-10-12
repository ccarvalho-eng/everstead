defmodule EverStead.Entities.Types do
  @moduledoc """
  Shared type definitions for game entities.

  This module centralizes common types used across multiple entities
  to ensure consistency and avoid duplication.
  """

  @typedoc """
  Resource types available in the game.
  """
  @type resource_type :: :wood | :stone | :food

  @typedoc """
  Resource inventory mapping resource types to amounts.
  """
  @type resource_inventory :: %{optional(resource_type()) => integer()}

  @typedoc """
  Season types in the game world.
  Seasons cycle through: spring -> summer -> fall -> winter -> spring
  """
  @type season_type :: :spring | :summer | :fall | :winter

  @typedoc """
  Villager profession types.
  """
  @type profession_type :: :builder | :farmer | :miner

  @typedoc """
  Coordinate tuple representing a position on the world map.
  """
  @type coordinate :: {integer(), integer()}
end
