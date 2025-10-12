defmodule EverStead.Constants.Building do
  @moduledoc """
  Building-related game constants and configurations.

  Defines resource costs and construction rates for all building types.
  """

  @doc """
  Resource costs for each building type.
  Returns a map with wood, stone, and food costs.
  """
  def cost(:house), do: %{wood: 50, stone: 20, food: 0}
  def cost(:farm), do: %{wood: 30, stone: 10, food: 0}
  def cost(:lumberyard), do: %{wood: 40, stone: 30, food: 0}
  def cost(:storage), do: %{wood: 60, stone: 40, food: 0}
  def cost(_), do: %{wood: 0, stone: 0, food: 0}

  @doc """
  Construction progress per tick for each building type.
  """
  def construction_rate(:house), do: 10
  def construction_rate(:farm), do: 8
  def construction_rate(:lumberyard), do: 12
  def construction_rate(:storage), do: 15
  def construction_rate(_), do: 10
end
