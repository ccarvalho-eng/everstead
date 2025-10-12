defmodule EverStead.Constants.Villager do
  @moduledoc """
  Villager-related game constants and configurations.

  Defines gathering rates and movement speed for villagers.
  """

  @doc """
  Resource gathering rates per tick by resource type.
  """
  def gathering_rate(:wood), do: 5
  def gathering_rate(:stone), do: 3
  def gathering_rate(:food), do: 8
  def gathering_rate(_), do: 5

  @doc """
  Villager movement speed in tiles per tick.
  """
  def movement_speed, do: 1
end
