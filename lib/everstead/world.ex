defmodule Everstead.World do
  @moduledoc """
  Context module for world-related operations.

  Handles season progression, multipliers, and other world mechanics.
  """

  alias Everstead.Entities.World.Season

  @season_duration 60
  @resource_multipliers %{spring: 1.0, summer: 1.2, fall: 1.1, winter: 0.7}
  @farming_multipliers %{spring: 1.3, summer: 1.5, fall: 1.2, winter: 0.3}
  @construction_multipliers %{spring: 1.1, summer: 1.2, fall: 1.0, winter: 0.6}

  @doc """
  Returns the duration of a season in ticks.

  ## Examples

      iex> World.season_duration()
      60
  """
  @spec season_duration() :: integer()
  def season_duration, do: @season_duration

  @doc """
  Returns the next season in the cycle.

  ## Examples

      iex> World.next_season(:spring)
      :summer

      iex> World.next_season(:winter)
      :spring
  """
  @spec next_season(atom()) :: atom()
  def next_season(:spring), do: :summer
  def next_season(:summer), do: :fall
  def next_season(:fall), do: :winter
  def next_season(:winter), do: :spring

  @doc """
  Advances the season by one tick.

  If the season duration is reached, progresses to the next season.
  When winter transitions to spring, increments the year.

  ## Examples

      iex> season = %Season{current: :spring, ticks_elapsed: 59, year: 1}
      iex> World.tick_season(season)
      %Season{current: :summer, ticks_elapsed: 0, year: 1}

      iex> season = %Season{current: :winter, ticks_elapsed: 59, year: 1}
      iex> World.tick_season(season)
      %Season{current: :spring, ticks_elapsed: 0, year: 2}
  """
  @spec tick_season(Season.t()) :: Season.t()
  def tick_season(%Season{ticks_elapsed: ticks} = season)
      when ticks + 1 >= @season_duration do
    new_season = next_season(season.current)
    new_year = if new_season == :spring, do: season.year + 1, else: season.year

    %{season | current: new_season, ticks_elapsed: 0, year: new_year}
  end

  def tick_season(%Season{} = season) do
    %{season | ticks_elapsed: season.ticks_elapsed + 1}
  end

  @doc """
  Returns a float multiplier for resource gathering based on season.

  ## Examples

      iex> World.resource_multiplier(:summer)
      1.2

      iex> World.resource_multiplier(:winter)
      0.7
  """
  @spec resource_multiplier(atom()) :: float()
  def resource_multiplier(season), do: Map.get(@resource_multipliers, season, 1.0)

  @doc """
  Returns a float multiplier for farming based on season.

  ## Examples

      iex> World.farming_multiplier(:summer)
      1.5

      iex> World.farming_multiplier(:winter)
      0.3
  """
  @spec farming_multiplier(atom()) :: float()
  def farming_multiplier(season), do: Map.get(@farming_multipliers, season, 1.0)

  @doc """
  Returns a float multiplier for construction speed based on season.

  ## Examples

      iex> World.construction_multiplier(:summer)
      1.2

      iex> World.construction_multiplier(:winter)
      0.6
  """
  @spec construction_multiplier(atom()) :: float()
  def construction_multiplier(season), do: Map.get(@construction_multipliers, season, 1.0)

  @doc """
  Returns the season as a human-readable string.

  ## Examples

      iex> World.season_to_string(:spring)
      "Spring"
  """
  @spec season_to_string(atom()) :: String.t()
  def season_to_string(season) do
    season
    |> Atom.to_string()
    |> String.capitalize()
  end
end
