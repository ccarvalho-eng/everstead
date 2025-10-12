defmodule EverStead.Constants do
  @moduledoc """
  Central repository for all game constants, configurations, and type definitions.

  This module re-exports functionality from specialized submodules:
  - `Constants.Season` - Season configurations and multipliers
  - `Constants.Villager` - Villager behavior constants
  - `Constants.Building` - Building costs and construction rates
  """

  alias EverStead.Constants.{Building, Season, Villager}

  # Season delegations
  defdelegate season_duration, to: Season, as: :duration
  defdelegate resource_multiplier(season), to: Season
  defdelegate farming_multiplier(season), to: Season
  defdelegate construction_multiplier(season), to: Season

  # Villager delegations
  defdelegate gathering_rate(resource_type), to: Villager
  defdelegate movement_speed, to: Villager

  # Building delegations
  defdelegate building_cost(building_type), to: Building, as: :cost
  defdelegate construction_rate(building_type), to: Building
end
