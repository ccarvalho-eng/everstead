defmodule EverStead.Entities.Season do
  @moduledoc """
  Represents a season in the game world.

  Seasons cycle through Spring, Summer, Fall, and Winter, each lasting
  a configurable number of ticks. Different seasons affect resource
  gathering rates, villager efficiency, and other game mechanics.
  """
  use TypedStruct

  @type season_type :: :spring | :summer | :fall | :winter

  @doc """
  Duration of each season in ticks (game seconds).
  Default: 60 ticks = 1 minute per season
  """
  @season_duration 60

  typedstruct do
    field :current, season_type(), default: :spring
    field :ticks_elapsed, integer(), default: 0
    field :year, integer(), default: 1
  end

  @doc """
  Returns the duration of a season in ticks.

  ## Examples

      iex> Season.season_duration()
      60
  """
  @spec season_duration() :: integer()
  def season_duration, do: @season_duration

  @doc """
  Returns the next season in the cycle.

  ## Examples

      iex> Season.next_season(:spring)
      :summer

      iex> Season.next_season(:winter)
      :spring
  """
  @spec next_season(season_type()) :: season_type()
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
      iex> Season.tick(season)
      %Season{current: :summer, ticks_elapsed: 0, year: 1}

      iex> season = %Season{current: :winter, ticks_elapsed: 59, year: 1}
      iex> Season.tick(season)
      %Season{current: :spring, ticks_elapsed: 0, year: 2}
  """
  @spec tick(t()) :: t()
  def tick(%__MODULE__{ticks_elapsed: ticks} = season) when ticks + 1 >= @season_duration do
    new_season = next_season(season.current)
    new_year = if new_season == :spring, do: season.year + 1, else: season.year

    %{season | current: new_season, ticks_elapsed: 0, year: new_year}
  end

  def tick(%__MODULE__{} = season) do
    %{season | ticks_elapsed: season.ticks_elapsed + 1}
  end

  @doc """
  Returns a float multiplier for resource gathering based on season.

  - Spring: 1.0 (normal)
  - Summer: 1.2 (20% bonus)
  - Fall: 1.1 (10% bonus)
  - Winter: 0.7 (30% penalty)

  ## Examples

      iex> Season.resource_multiplier(:summer)
      1.2

      iex> Season.resource_multiplier(:winter)
      0.7
  """
  @spec resource_multiplier(season_type()) :: float()
  def resource_multiplier(:spring), do: 1.0
  def resource_multiplier(:summer), do: 1.2
  def resource_multiplier(:fall), do: 1.1
  def resource_multiplier(:winter), do: 0.7

  @doc """
  Returns a float multiplier for farming based on season.

  - Spring: 1.3 (30% bonus - planting season)
  - Summer: 1.5 (50% bonus - growing season)
  - Fall: 1.2 (20% bonus - harvest season)
  - Winter: 0.3 (70% penalty - harsh conditions)

  ## Examples

      iex> Season.farming_multiplier(:summer)
      1.5

      iex> Season.farming_multiplier(:winter)
      0.3
  """
  @spec farming_multiplier(season_type()) :: float()
  def farming_multiplier(:spring), do: 1.3
  def farming_multiplier(:summer), do: 1.5
  def farming_multiplier(:fall), do: 1.2
  def farming_multiplier(:winter), do: 0.3

  @doc """
  Returns a float multiplier for construction speed based on season.

  - Spring: 1.1 (10% bonus)
  - Summer: 1.2 (20% bonus - ideal conditions)
  - Fall: 1.0 (normal)
  - Winter: 0.6 (40% penalty - harsh conditions)

  ## Examples

      iex> Season.construction_multiplier(:summer)
      1.2

      iex> Season.construction_multiplier(:winter)
      0.6
  """
  @spec construction_multiplier(season_type()) :: float()
  def construction_multiplier(:spring), do: 1.1
  def construction_multiplier(:summer), do: 1.2
  def construction_multiplier(:fall), do: 1.0
  def construction_multiplier(:winter), do: 0.6

  @doc """
  Returns the season as a human-readable string.

  ## Examples

      iex> Season.to_string(:spring)
      "Spring"
  """
  @spec to_string(season_type()) :: String.t()
  def to_string(season) do
    season
    |> Atom.to_string()
    |> String.capitalize()
  end
end
