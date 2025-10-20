defmodule Everstead.World do
  @moduledoc """
  Context module for world-related operations.

  Handles season progression, multipliers, and other world mechanics.
  Features a realistic time system with named years, day/night cycles,
  and immersive logging similar to Skyrim.
  """

  alias Everstead.Entities.World.Season

  # 5 minutes per season (300 seconds)
  @season_duration 300
  @resource_multipliers %{spring: 1.0, summer: 1.2, fall: 1.1, winter: 0.7}
  @farming_multipliers %{spring: 1.3, summer: 1.5, fall: 1.2, winter: 0.3}
  @construction_multipliers %{spring: 1.1, summer: 1.2, fall: 1.0, winter: 0.6}
  @movement_multipliers %{spring: 1.0, summer: 1.1, fall: 0.9, winter: 0.7}
  @food_consumption_multipliers %{spring: 1.0, summer: 1.2, fall: 1.1, winter: 1.3}

  # Named years for immersive fantasy calendar system
  @named_years [
    "The First Dawn",
    "The Awakening",
    "The Great Founding",
    "The Golden Age",
    "The Silver Era",
    "The Bronze Years",
    "The Iron Times",
    "The Steel Reign",
    "The Emerald Age",
    "The Ruby Years",
    "The Sapphire Era",
    "The Diamond Age",
    "The Crystal Times",
    "The Pearl Years",
    "The Opal Era",
    "The Jade Age",
    "The Topaz Years",
    "The Amethyst Era",
    "The Garnet Age",
    "The Onyx Times",
    "The Obsidian Years",
    "The Marble Era",
    "The Granite Age",
    "The Quartz Years",
    "The Flint Times",
    "The Thunder Years",
    "The Lightning Era",
    "The Storm Age",
    "The Wind Times",
    "The Rain Years",
    "The Snow Era",
    "The Ice Age",
    "The Frost Years",
    "The Blizzard Times",
    "The Hail Years",
    "The Sun Era",
    "The Moon Age",
    "The Star Years",
    "The Comet Times",
    "The Eclipse Years",
    "The Harvest Era",
    "The Planting Age",
    "The Growth Years",
    "The Bloom Times",
    "The Fruit Years",
    "The Bounty Era",
    "The Plenty Age",
    "The Abundance Years",
    "The Prosperity Times",
    "The Wealth Years"
  ]

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
  Returns a float multiplier for villager movement speed based on season.

  ## Examples

      iex> World.movement_multiplier(:summer)
      1.1

      iex> World.movement_multiplier(:winter)
      0.7
  """
  @spec movement_multiplier(atom()) :: float()
  def movement_multiplier(season), do: Map.get(@movement_multipliers, season, 1.0)

  @doc """
  Returns a float multiplier for food consumption based on season.

  ## Examples

      iex> World.food_consumption_multiplier(:summer)
      1.2

      iex> World.food_consumption_multiplier(:winter)
      1.3
  """
  @spec food_consumption_multiplier(atom()) :: float()
  def food_consumption_multiplier(season), do: Map.get(@food_consumption_multipliers, season, 1.0)

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

  @doc """
  Returns the year name for a given year number.
  Uses a cycling list of fantasy year names for immersive world building.

  ## Examples

      iex> World.year_name(1)
      "The First Dawn"

      iex> World.year_name(5)
      "The Golden Age"
  """
  @spec year_name(integer()) :: String.t()
  def year_name(year) when year > 0 do
    # Cycle through the named years, wrapping around
    index = rem(year - 1, length(@named_years))
    Enum.at(@named_years, index)
  end

  @doc """
  Returns the day of the season (1-based).
  Each day has 60 ticks (dawn, morning, afternoon, evening).

  ## Examples

      iex> World.day_of_season(%Season{ticks_elapsed: 5})
      1
      iex> World.day_of_season(%Season{ticks_elapsed: 65})
      2
  """
  @spec day_of_season(Season.t()) :: integer()
  def day_of_season(%Season{ticks_elapsed: ticks}), do: div(ticks, 60) + 1

  @doc """
  Returns the time of day based on tick within the day.
  Each day has 60 ticks with 4 time periods.

  ## Examples

      iex> World.time_of_day(%Season{ticks_elapsed: 15})
      "Morning"
  """
  @spec time_of_day(Season.t()) :: String.t()
  def time_of_day(%Season{ticks_elapsed: ticks}) do
    # Calculate the actual clock time to determine time period
    total_minutes = rem(ticks, 60) * 24
    hours = div(total_minutes, 60)

    cond do
      # Night: 22:00-04:59 (10 PM - 5 AM)
      hours >= 22 or hours < 5 -> "Night"
      # Dawn: 05:00-06:59 (5 AM - 7 AM)
      hours >= 5 and hours < 7 -> "Dawn"
      # Morning: 07:00-11:59 (7 AM - 12 PM)
      hours >= 7 and hours < 12 -> "Morning"
      # Afternoon: 12:00-16:59 (12 PM - 5 PM)
      hours >= 12 and hours < 17 -> "Afternoon"
      # Evening: 17:00-19:59 (5 PM - 8 PM)
      hours >= 17 and hours < 20 -> "Evening"
      # Dusk: 20:00-21:59 (8 PM - 10 PM)
      hours >= 20 and hours < 22 -> "Dusk"
      # fallback
      true -> "Night"
    end
  end

  @doc """
  Returns a simulated clock time based on ticks within the day.
  Each day has 60 ticks, simulating 24 hours (1 tick = 24 minutes).

  ## Examples

      iex> World.clock_time(%Season{ticks_elapsed: 15})
      "06:00"
  """
  @spec clock_time(Season.t()) :: String.t()
  def clock_time(%Season{ticks_elapsed: ticks}) do
    # Each tick represents 24 minutes (60 ticks * 24 minutes = 1440 minutes = 24 hours)
    total_minutes = rem(ticks, 60) * 24
    hours = div(total_minutes, 60)
    minutes = rem(total_minutes, 60)

    # Format as HH:MM
    "#{String.pad_leading(to_string(hours), 2, "0")}:#{String.pad_leading(to_string(minutes), 2, "0")}"
  end

  @doc """
  Returns a detailed clock time with seconds for more precision.
  Each tick represents 24 minutes, so we can simulate seconds within each tick.

  ## Examples

      iex> World.detailed_clock_time(%Season{ticks_elapsed: 15})
      "06:00:00"
  """
  @spec detailed_clock_time(Season.t()) :: String.t()
  def detailed_clock_time(%Season{ticks_elapsed: ticks}) do
    # Each tick represents 24 minutes (1440 seconds)
    # We'll simulate seconds by using the tick number as seconds within the minute
    total_seconds = rem(ticks, 60) * 1440
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    # Format as HH:MM:SS
    "#{String.pad_leading(to_string(hours), 2, "0")}:#{String.pad_leading(to_string(minutes), 2, "0")}:#{String.pad_leading(to_string(seconds), 2, "0")}"
  end

  @doc """
  Returns the number of days until the next season.
  Each season lasts 300 ticks (5 days), each day has 60 ticks.

  ## Examples

      iex> World.days_until_next_season(%Season{ticks_elapsed: 50})
      4
      iex> World.days_until_next_season(%Season{ticks_elapsed: 250})
      0
  """
  @spec days_until_next_season(Season.t()) :: integer()
  def days_until_next_season(%Season{ticks_elapsed: ticks}) do
    ticks_remaining = @season_duration - ticks
    days_remaining = div(ticks_remaining, 60)
    days_remaining
  end

  @doc """
  Returns the number of ticks until the next season.

  ## Examples

      iex> World.ticks_until_next_season(%Season{ticks_elapsed: 50})
      250
  """
  @spec ticks_until_next_season(Season.t()) :: integer()
  def ticks_until_next_season(%Season{ticks_elapsed: ticks}) do
    @season_duration - ticks
  end

  @doc """
  Returns a formatted date string with year name, season, day, and time.

  ## Examples

      iex> season = %Season{current: :spring, ticks_elapsed: 15, year: 1}
      iex> World.format_date(season)
      "The First Dawn, Spring - Day 16, Morning"
  """
  @spec format_date(Season.t()) :: String.t()
  def format_date(%Season{} = season) do
    year_name = year_name(season.year)
    season_name = season_to_string(season.current)
    day = day_of_season(season)
    time = time_of_day(season)

    "#{year_name}, #{season_name} - Day #{day}, #{time}"
  end

  @doc """
  Returns a readable time string for logs.

  ## Examples

      iex> season = %Season{current: :spring, ticks_elapsed: 15, year: 1}
      iex> World.format_time_readable(season)
      "Year 1, Spring - Day 16, Morning"
  """
  @spec format_time_readable(Season.t()) :: String.t()
  def format_time_readable(%Season{} = season) do
    day = day_of_season(season)
    time = time_of_day(season)
    season_name = season_to_string(season.current)

    "Year #{season.year}, #{season_name} - Day #{day}, #{time}"
  end

  @doc """
  Returns weather conditions based on season and time.

  ## Examples

      iex> World.get_weather(:spring, "Morning")
      "Gentle breeze and scattered clouds"
  """
  @spec get_weather(atom(), String.t()) :: String.t()
  def get_weather(season, time) do
    case {season, time} do
      {:spring, "Night"} -> "Starry sky with cool night air"
      {:spring, "Dawn"} -> "Misty morning with dew on the grass"
      {:spring, "Morning"} -> "Gentle breeze and scattered clouds"
      {:spring, "Afternoon"} -> "Warm sunshine with light winds"
      {:spring, "Evening"} -> "Cool air as the sun sets"
      {:spring, "Dusk"} -> "Twilight with gentle evening breeze"
      {:summer, "Night"} -> "Warm night with clear starry sky"
      {:summer, "Dawn"} -> "Clear skies with morning warmth"
      {:summer, "Morning"} -> "Bright sunshine and clear skies"
      {:summer, "Afternoon"} -> "Hot sun with occasional clouds"
      {:summer, "Evening"} -> "Warm evening with golden light"
      {:summer, "Dusk"} -> "Warm twilight with lingering heat"
      {:fall, "Night"} -> "Crisp night air with rustling leaves"
      {:fall, "Dawn"} -> "Crisp air with fallen leaves"
      {:fall, "Morning"} -> "Cool breeze and overcast skies"
      {:fall, "Afternoon"} -> "Mild temperatures with rustling leaves"
      {:fall, "Evening"} -> "Chilly air as darkness falls"
      {:fall, "Dusk"} -> "Cool twilight with falling leaves"
      {:winter, "Night"} -> "Freezing night with clear cold sky"
      {:winter, "Dawn"} -> "Frost-covered ground and cold air"
      {:winter, "Morning"} -> "Cold winds and gray skies"
      {:winter, "Afternoon"} -> "Bitter cold with occasional snow"
      {:winter, "Evening"} -> "Freezing temperatures and darkness"
      {:winter, "Dusk"} -> "Cold twilight with frost forming"
    end
  end

  @doc """
  Returns a random world event based on season and time.

  ## Examples

      iex> World.get_world_event(:spring, "Morning")
      "A merchant caravan approaches from the east"
  """
  @spec get_world_event(atom(), String.t()) :: String.t()
  def get_world_event(season, time) do
    events =
      case {season, time} do
        {:spring, "Dawn"} ->
          [
            "A merchant caravan approaches from the east",
            "Birds are singing in the nearby trees",
            "Fresh flowers bloom in the meadows",
            "A gentle rain begins to fall",
            "Morning mist rises from the valleys",
            "The first rays of sun touch the mountain peaks",
            "A deer grazes peacefully in the clearing",
            "The sound of a distant waterfall echoes softly"
          ]

        {:spring, "Morning"} ->
          [
            "Birds are singing in the nearby trees",
            "Fresh flowers bloom in the meadows",
            "A gentle rain begins to fall",
            "Bees buzz busily among the blossoms",
            "A family of rabbits hops through the grass",
            "The morning air is filled with the scent of new growth",
            "A hawk soars high above the kingdom",
            "The sound of a blacksmith's hammer rings out"
          ]

        {:spring, "Afternoon"} ->
          [
            "A merchant caravan approaches from the east",
            "The sun warms the earth after winter's chill",
            "Children can be heard playing in the village",
            "A gentle breeze carries the scent of wildflowers",
            "Farmers work in the fields preparing for planting",
            "The sound of a lute drifts from the tavern",
            "A group of travelers rests by the roadside",
            "The afternoon light filters through the new leaves"
          ]

        {:spring, "Evening"} ->
          [
            "The evening air carries the promise of new life",
            "Fireflies begin to twinkle in the gathering dusk",
            "The sound of evening prayers rises from the chapel",
            "A gentle rain begins to fall",
            "The last rays of sun paint the clouds in pastels",
            "A nightingale's song fills the twilight",
            "The scent of evening primrose fills the air",
            "Villagers gather around the evening fire"
          ]

        {:spring, "Dusk"} ->
          [
            "The twilight hour brings peace to the kingdom",
            "Stars begin to appear in the darkening sky",
            "The sound of evening bells rings across the valley",
            "A gentle breeze carries the scent of night-blooming flowers",
            "The last light of day fades behind the mountains",
            "A family of owls begins their nightly hunt",
            "The evening air is filled with the sound of crickets",
            "The first stars twinkle in the purple sky"
          ]

        {:spring, "Night"} ->
          [
            "The night is alive with the sounds of spring",
            "A full moon casts silver light across the land",
            "The sound of a distant wolf howl echoes through the valley",
            "Fireflies dance in the darkness like tiny stars",
            "The night air is filled with the scent of blooming flowers",
            "A gentle rain falls softly in the moonlight",
            "The stars shine brightly in the clear spring sky",
            "The sound of a nightingale's song fills the darkness"
          ]

        {:summer, "Dawn"} ->
          [
            "The sun beats down with intense heat",
            "A cool breeze brings relief from the heat",
            "Thunder rumbles in the distance",
            "Wildlife is active in the forests",
            "The morning air is already warm and humid",
            "Cicadas begin their daily chorus",
            "The first light reveals a clear blue sky",
            "A gentle morning breeze stirs the tall grass"
          ]

        {:summer, "Morning"} ->
          [
            "The sun beats down with intense heat",
            "A cool breeze brings relief from the heat",
            "Wildlife is active in the forests",
            "The morning sun is already strong and bright",
            "Bees work tirelessly in the flower gardens",
            "The sound of a distant thunderstorm approaches",
            "A family of ducks swims in the village pond",
            "The air shimmers with heat waves"
          ]

        {:summer, "Afternoon"} ->
          [
            "The sun beats down with intense heat",
            "A cool breeze brings relief from the heat",
            "Thunder rumbles in the distance",
            "Wildlife is active in the forests",
            "The afternoon heat is almost unbearable",
            "A sudden gust of wind brings welcome relief",
            "The sound of children splashing in the river",
            "Clouds begin to gather on the horizon"
          ]

        {:summer, "Evening"} ->
          [
            "The evening brings welcome relief from the heat",
            "Fireflies dance in the warm twilight",
            "The sound of crickets fills the night air",
            "A gentle evening breeze stirs the leaves",
            "The setting sun paints the sky in brilliant colors",
            "The air is thick with the scent of summer flowers",
            "A distant lightning storm illuminates the horizon",
            "The evening air is alive with the sounds of summer"
          ]

        {:summer, "Dusk"} ->
          [
            "The warm twilight brings comfort to the kingdom",
            "The evening air is alive with the sounds of summer",
            "A gentle breeze carries the scent of jasmine",
            "The last light of day fades in a blaze of color",
            "The sound of evening birds fills the air",
            "A family of bats begins their nightly flight",
            "The evening air is thick with the scent of honeysuckle",
            "The stars begin to appear in the darkening sky"
          ]

        {:summer, "Night"} ->
          [
            "The warm summer night is alive with activity",
            "A full moon illuminates the kingdom in silver light",
            "The sound of crickets and frogs fills the night air",
            "Fireflies create a magical light show in the darkness",
            "The night air is thick with the scent of summer flowers",
            "A gentle breeze brings relief from the day's heat",
            "The stars shine brightly in the clear summer sky",
            "The sound of a distant thunderstorm rumbles softly"
          ]

        {:fall, "Dawn"} ->
          [
            "Leaves fall gently from the trees",
            "A harvest festival can be heard in the distance",
            "Mist rises from the nearby river",
            "The air carries the scent of autumn",
            "The morning air is crisp and cool",
            "Geese fly overhead in formation",
            "The first light reveals a carpet of fallen leaves",
            "The sound of a distant hunting horn echoes"
          ]

        {:fall, "Morning"} ->
          [
            "Leaves fall gently from the trees",
            "A harvest festival can be heard in the distance",
            "The air carries the scent of autumn",
            "The morning air is crisp and invigorating",
            "Squirrels scurry about gathering nuts",
            "The sound of threshing can be heard from the fields",
            "A gentle wind carries the scent of wood smoke",
            "The morning light filters through golden leaves"
          ]

        {:fall, "Afternoon"} ->
          [
            "Leaves fall gently from the trees",
            "A harvest festival can be heard in the distance",
            "Mist rises from the nearby river",
            "The air carries the scent of autumn",
            "The afternoon sun casts long shadows",
            "The sound of a distant harvest song drifts on the wind",
            "A gentle rain of golden leaves falls from the trees",
            "The air is filled with the scent of ripe apples"
          ]

        {:fall, "Evening"} ->
          [
            "Leaves fall gently from the trees",
            "A harvest festival can be heard in the distance",
            "Mist rises from the nearby river",
            "The air carries the scent of autumn",
            "The evening air is cool and refreshing",
            "The sound of a distant owl hoots in the twilight",
            "The setting sun sets the leaves ablaze with color",
            "The evening air is filled with the scent of burning leaves"
          ]

        {:fall, "Dusk"} ->
          [
            "The autumn twilight brings a sense of peace",
            "The evening air is filled with the scent of fallen leaves",
            "A gentle breeze stirs the golden leaves",
            "The last light of day illuminates the colorful trees",
            "The sound of evening birds fills the crisp air",
            "A family of deer grazes peacefully in the clearing",
            "The evening air is cool and invigorating",
            "The first stars appear in the darkening sky"
          ]

        {:fall, "Night"} ->
          [
            "The autumn night is filled with the sounds of the season",
            "A harvest moon casts golden light across the land",
            "The sound of owls hooting fills the night air",
            "The night air is crisp and filled with the scent of autumn",
            "A gentle wind rustles the fallen leaves",
            "The stars shine brightly in the clear autumn sky",
            "The sound of a distant wolf howl echoes through the valley",
            "The night air is alive with the sounds of autumn"
          ]

        {:winter, "Dawn"} ->
          [
            "Snow begins to fall softly",
            "The wind howls through the valleys",
            "Icicles form on the rooftops",
            "A wolf howls in the distance",
            "The morning air is bitterly cold",
            "The first light reveals a world covered in frost",
            "The sound of cracking ice echoes from the frozen pond",
            "A gentle snow begins to fall from the gray sky"
          ]

        {:winter, "Morning"} ->
          [
            "Snow begins to fall softly",
            "The wind howls through the valleys",
            "Icicles form on the rooftops",
            "A wolf howls in the distance",
            "The morning air is crisp and cold",
            "The sound of a distant sleigh bell rings out",
            "A family of deer searches for food in the snow",
            "The morning light is pale and weak"
          ]

        {:winter, "Afternoon"} ->
          [
            "Snow begins to fall softly",
            "The wind howls through the valleys",
            "Icicles form on the rooftops",
            "A wolf howls in the distance",
            "The afternoon sun provides little warmth",
            "The sound of a distant ice storm approaches",
            "A gentle snow begins to fall from the gray sky",
            "The afternoon light is dim and gray"
          ]

        {:winter, "Evening"} ->
          [
            "Snow begins to fall softly",
            "The wind howls through the valleys",
            "Icicles form on the rooftops",
            "A wolf howls in the distance",
            "The evening air is bitterly cold",
            "The sound of a distant ice storm approaches",
            "The evening light is pale and weak",
            "A gentle snow begins to fall from the gray sky"
          ]

        {:winter, "Dusk"} ->
          [
            "The winter twilight brings an eerie silence",
            "The evening air is bitterly cold and still",
            "A gentle snow begins to fall in the fading light",
            "The last light of day reveals a world covered in frost",
            "The sound of cracking ice echoes in the stillness",
            "A family of wolves begins their nightly hunt",
            "The evening air is filled with the sound of wind",
            "The first stars appear in the darkening winter sky"
          ]

        {:winter, "Night"} ->
          [
            "The winter night is silent and still",
            "A full moon illuminates the snow-covered landscape",
            "The sound of wind howling through the valleys",
            "The night air is bitterly cold and crisp",
            "A gentle snow falls softly in the moonlight",
            "The stars shine brightly in the clear winter sky",
            "The sound of a distant wolf pack echoes through the night",
            "The night air is filled with the sound of cracking ice"
          ]
      end

    Enum.random(events)
  end
end
