defmodule EverStead.Constants.Season do
  @moduledoc """
  Season-related game constants and configurations.

  Defines season duration and seasonal multipliers for various activities.
  """

  @doc """
  Duration of each season in ticks (game seconds).
  Default: 60 ticks = 1 minute per season
  """
  def duration, do: 60

  @doc """
  Resource gathering multiplier by season.

  - Spring: 1.0 (normal)
  - Summer: 1.2 (20% bonus)
  - Fall: 1.1 (10% bonus)
  - Winter: 0.7 (30% penalty)
  """
  def resource_multiplier(:spring), do: 1.0
  def resource_multiplier(:summer), do: 1.2
  def resource_multiplier(:fall), do: 1.1
  def resource_multiplier(:winter), do: 0.7

  @doc """
  Farming multiplier by season.

  - Spring: 1.3 (30% bonus - planting season)
  - Summer: 1.5 (50% bonus - growing season)
  - Fall: 1.2 (20% bonus - harvest season)
  - Winter: 0.3 (70% penalty - harsh conditions)
  """
  def farming_multiplier(:spring), do: 1.3
  def farming_multiplier(:summer), do: 1.5
  def farming_multiplier(:fall), do: 1.2
  def farming_multiplier(:winter), do: 0.3

  @doc """
  Construction speed multiplier by season.

  - Spring: 1.1 (10% bonus)
  - Summer: 1.2 (20% bonus - ideal conditions)
  - Fall: 1.0 (normal)
  - Winter: 0.6 (40% penalty - harsh conditions)
  """
  def construction_multiplier(:spring), do: 1.1
  def construction_multiplier(:summer), do: 1.2
  def construction_multiplier(:fall), do: 1.0
  def construction_multiplier(:winter), do: 0.6
end
