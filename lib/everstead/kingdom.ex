defmodule Everstead.Kingdom do
  @moduledoc """
  Context module for kingdom operations including resource management and building.
  """

  alias Everstead.Entities.Player
  alias Everstead.Entities.World.Kingdom
  alias Everstead.Entities.World.Kingdom.Building
  alias Everstead.Entities.World.Resource
  alias Everstead.Entities.World.Tile
  alias Everstead.World

  @building_costs %{
    house: %{wood: 50, stone: 20, food: 0},
    farm: %{wood: 30, stone: 10, food: 0},
    lumberyard: %{wood: 40, stone: 30, food: 0},
    storage: %{wood: 60, stone: 40, food: 0}
  }

  @construction_rates %{
    house: 10,
    farm: 8,
    lumberyard: 12,
    storage: 15
  }

  @type build_result :: {:ok, {Player.t(), Building.t()}} | {:error, atom()}
  @type validation_result :: :ok | {:error, atom()}

  @doc """
  Gets the amount of a specific resource type in the kingdom.

  Returns 0 if the resource is not found.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.get_resource_amount(kingdom, :wood)
      100

      iex> kingdom = %Kingdom{resources: []}
      iex> Kingdom.get_resource_amount(kingdom, :wood)
      0
  """
  @spec get_resource_amount(Kingdom.t(), atom()) :: integer()
  def get_resource_amount(kingdom, resource_type) do
    case Enum.find(kingdom.resources, fn r -> r.type == resource_type end) do
      nil -> 0
      resource -> resource.amount
    end
  end

  @doc """
  Checks if the kingdom has enough resources to cover the given costs.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.has_resources?(kingdom, %{wood: 50})
      true

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.has_resources?(kingdom, %{wood: 150})
      false
  """
  @spec has_resources?(Kingdom.t(), map()) :: boolean()
  def has_resources?(kingdom, costs) do
    Enum.all?(costs, fn {resource_type, required_amount} ->
      get_resource_amount(kingdom, resource_type) >= required_amount
    end)
  end

  @doc """
  Deducts resources from the kingdom.

  Returns the updated kingdom with reduced resource amounts.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> updated = Kingdom.deduct_resources(kingdom, %{wood: 50})
      iex> Kingdom.get_resource_amount(updated, :wood)
      50
  """
  @spec deduct_resources(Kingdom.t(), map()) :: Kingdom.t()
  def deduct_resources(kingdom, costs) do
    updated_resources =
      Enum.map(kingdom.resources, fn resource ->
        case Map.get(costs, resource.type) do
          nil -> resource
          amount -> %{resource | amount: resource.amount - amount}
        end
      end)

    %{kingdom | resources: updated_resources}
  end

  @doc """
  Adds resources to the kingdom.

  Returns the updated kingdom with increased resource amounts.
  If a resource type doesn't exist, it will be created.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> updated = Kingdom.add_resources(kingdom, %{wood: 50})
      iex> Kingdom.get_resource_amount(updated, :wood)
      150
  """
  @spec add_resources(Kingdom.t(), map()) :: Kingdom.t()
  def add_resources(kingdom, additions) do
    updated_resources =
      Enum.reduce(additions, kingdom.resources, fn {resource_type, amount}, resources ->
        case Enum.find_index(resources, fn r -> r.type == resource_type end) do
          nil ->
            # Resource doesn't exist, add it
            [%Resource{type: resource_type, amount: amount} | resources]

          index ->
            # Resource exists, update it
            List.update_at(resources, index, fn r ->
              %{r | amount: r.amount + amount}
            end)
        end
      end)

    %{kingdom | resources: updated_resources}
  end

  # Building Functions

  @doc """
  Places a new building at the specified location.

  Validates terrain, checks resource availability, and deducts costs.

  ## Examples

      iex> player = %Player{id: "p1", kingdom: %Kingdom{resources: [%Resource{type: :wood, amount: 100}, %Resource{type: :stone, amount: 50}]}}
      iex> tile = %Tile{terrain: :grass, building_id: nil}
      iex> Kingdom.place_building(player, tile, :house, {5, 5})
      {:ok, {updated_player, new_building}}

      iex> player = %Player{id: "p1", kingdom: %Kingdom{resources: [%Resource{type: :wood, amount: 10}, %Resource{type: :stone, amount: 5}]}}
      iex> tile = %Tile{terrain: :grass, building_id: nil}
      iex> Kingdom.place_building(player, tile, :house, {5, 5})
      {:error, :insufficient_resources}
  """
  @spec place_building(Player.t(), Tile.t(), Building.type(), {integer(), integer()}) ::
          build_result()
  def place_building(player, tile, building_type, location) do
    with :ok <- validate_terrain(tile),
         :ok <- validate_tile_available(tile),
         :ok <- validate_building_type(building_type),
         :ok <- validate_resources(player.kingdom, building_type) do
      building = create_building(building_type, location)
      updated_kingdom = deduct_building_resources(player.kingdom, building_type)
      updated_kingdom = add_building_to_kingdom(updated_kingdom, building)
      updated_player = %{player | kingdom: updated_kingdom}

      {:ok, {updated_player, building}}
    end
  end

  @doc """
  Advances construction progress for a building.

  Returns the updated building with increased construction progress.

  ## Examples

      iex> building = %Building{id: "b1", type: :house, construction_progress: 50}
      iex> Kingdom.advance_construction(building, 1)
      %Building{id: "b1", type: :house, construction_progress: 60}
  """
  @spec advance_construction(Building.t(), integer()) :: Building.t()
  def advance_construction(building, ticks \\ 1) do
    rate = Map.get(@construction_rates, building.type, 10)
    new_progress = min(building.construction_progress + rate * ticks, 100)
    %{building | construction_progress: new_progress}
  end

  @doc """
  Advances construction progress for a building with seasonal modifiers.

  Takes into account the current season's construction multiplier.
  - Summer: 20% faster construction
  - Spring: 10% faster construction
  - Fall: Normal speed
  - Winter: 40% slower construction

  ## Examples

      iex> building = %Building{id: "b1", type: :house, construction_progress: 0}
      iex> Kingdom.advance_construction_with_season(building, :summer, 1)
      %Building{id: "b1", type: :house, construction_progress: 12}

      iex> building = %Building{id: "b1", type: :house, construction_progress: 0}
      iex> Kingdom.advance_construction_with_season(building, :winter, 1)
      %Building{id: "b1", type: :house, construction_progress: 6}
  """
  @spec advance_construction_with_season(Building.t(), atom(), integer()) :: Building.t()
  def advance_construction_with_season(building, season, ticks \\ 1) do
    base_rate = Map.get(@construction_rates, building.type, 10)
    season_multiplier = World.construction_multiplier(season)
    effective_rate = floor(base_rate * season_multiplier)
    new_progress = min(building.construction_progress + effective_rate * ticks, 100)
    %{building | construction_progress: new_progress}
  end

  @doc """
  Checks if construction is complete.

  ## Examples

      iex> building = %Building{construction_progress: 100}
      iex> Kingdom.construction_complete?(building)
      true
  """
  @spec construction_complete?(Building.t()) :: boolean()
  def construction_complete?(building) do
    building.construction_progress >= 100
  end

  @doc """
  Cancels building construction and refunds resources.

  Refunds 50% of the original cost if construction is less than 50% complete.

  ## Examples

      iex> player = %Player{kingdom: %Kingdom{resources: [%Resource{type: :wood, amount: 10}, %Resource{type: :stone, amount: 5}]}}
      iex> building = %Building{type: :house, construction_progress: 30}
      iex> Kingdom.cancel_construction(player, building)
      {:ok, %Player{kingdom: %Kingdom{resources: [%Resource{type: :wood, amount: 35}, %Resource{type: :stone, amount: 15}]}}}
  """
  @spec cancel_construction(Player.t(), Building.t()) :: {:ok, Player.t()}
  def cancel_construction(player, building) do
    refund_percentage = if building.construction_progress < 50, do: 0.5, else: 0.0
    refunded_kingdom = refund_resources(player.kingdom, building.type, refund_percentage)
    updated_kingdom = remove_building_from_kingdom(refunded_kingdom, building.id)
    updated_player = %{player | kingdom: updated_kingdom}

    {:ok, updated_player}
  end

  @doc """
  Checks if a building can be placed at the specified location.

  ## Examples

      iex> tile = %Tile{terrain: :water, building_id: nil}
      iex> Kingdom.can_build_at?(tile, :house)
      {:error, :invalid_terrain}
  """
  @spec can_build_at?(Tile.t(), Building.type()) :: validation_result()
  def can_build_at?(tile, building_type) do
    with :ok <- validate_terrain(tile),
         :ok <- validate_tile_available(tile),
         :ok <- validate_building_type(building_type) do
      :ok
    end
  end

  @doc """
  Gets the resource cost for a building type.

  ## Examples

      iex> Kingdom.get_building_cost(:house)
      %{wood: 50, stone: 20, food: 0}
  """
  @spec get_building_cost(atom()) :: map()
  def get_building_cost(building_type) do
    Map.get(@building_costs, building_type, %{wood: 0, stone: 0, food: 0})
  end

  @doc """
  Gets the construction rate (progress per tick) for a building type.
  """
  @spec get_construction_rate(atom()) :: integer()
  def get_construction_rate(building_type) do
    Map.get(@construction_rates, building_type, 10)
  end

  # Private Building Functions

  @spec validate_terrain(Tile.t()) :: validation_result()
  defp validate_terrain(%Tile{terrain: :water}), do: {:error, :invalid_terrain}
  defp validate_terrain(%Tile{terrain: :mountain}), do: {:error, :invalid_terrain}
  defp validate_terrain(_tile), do: :ok

  @spec validate_tile_available(Tile.t()) :: validation_result()
  defp validate_tile_available(%Tile{building_id: nil}), do: :ok
  defp validate_tile_available(_tile), do: {:error, :tile_occupied}

  @spec validate_building_type(Building.type()) :: validation_result()
  defp validate_building_type(type) when type in [:house, :farm, :lumberyard, :storage], do: :ok
  defp validate_building_type(_type), do: {:error, :invalid_building_type}

  @spec validate_resources(Kingdom.t(), Building.type()) :: validation_result()
  defp validate_resources(kingdom, building_type) do
    cost = Map.get(@building_costs, building_type, %{wood: 0, stone: 0, food: 0})

    if has_resources?(kingdom, cost) do
      :ok
    else
      {:error, :insufficient_resources}
    end
  end

  @spec create_building(Building.type(), {integer(), integer()}) :: Building.t()
  defp create_building(building_type, location) do
    %Building{
      id: generate_building_id(),
      type: building_type,
      location: location,
      construction_progress: 0,
      hp: 100
    }
  end

  @spec deduct_building_resources(Kingdom.t(), Building.type()) :: Kingdom.t()
  defp deduct_building_resources(kingdom, building_type) do
    cost = Map.get(@building_costs, building_type, %{wood: 0, stone: 0, food: 0})
    deduct_resources(kingdom, cost)
  end

  @spec refund_resources(Kingdom.t(), Building.type(), float()) :: Kingdom.t()
  defp refund_resources(kingdom, building_type, percentage) do
    cost = Map.get(@building_costs, building_type, %{wood: 0, stone: 0, food: 0})

    refund_amounts =
      Enum.into(cost, %{}, fn {resource, amount} ->
        {resource, floor(amount * percentage)}
      end)

    add_resources(kingdom, refund_amounts)
  end

  @spec add_building_to_kingdom(Kingdom.t(), Building.t()) :: Kingdom.t()
  defp add_building_to_kingdom(kingdom, building) do
    updated_buildings = [building | kingdom.buildings]
    %{kingdom | buildings: updated_buildings}
  end

  @spec remove_building_from_kingdom(Kingdom.t(), String.t()) :: Kingdom.t()
  defp remove_building_from_kingdom(kingdom, building_id) do
    updated_buildings = Enum.reject(kingdom.buildings, fn b -> b.id == building_id end)
    %{kingdom | buildings: updated_buildings}
  end

  @spec generate_building_id() :: String.t()
  defp generate_building_id do
    "building_#{:erlang.unique_integer([:positive, :monotonic])}"
  end
end
