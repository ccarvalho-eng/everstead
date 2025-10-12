defmodule EverStead.Simulation.KingdomBuilder do
  @moduledoc """
  Handles kingdom building logic including:
  - Building placement and validation
  - Resource cost management
  - Construction progress tracking
  """

  alias EverStead.Entities.{Building, Player, Tile}

  @type build_result :: {:ok, {Player.t(), Building.t()}} | {:error, atom()}
  @type validation_result :: :ok | {:error, atom()}

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

  @doc """
  Places a new building at the specified location.

  Validates terrain, checks resource availability, and deducts costs.

  ## Examples

      iex> player = %Player{id: "p1", resources: %{wood: 100, stone: 50, food: 10}}
      iex> tile = %Tile{terrain: :grass, building_id: nil}
      iex> KingdomBuilder.place_building(player, tile, :house, {5, 5})
      {:ok, {updated_player, new_building}}

      iex> player = %Player{id: "p1", resources: %{wood: 10, stone: 5, food: 0}}
      iex> tile = %Tile{terrain: :grass, building_id: nil}
      iex> KingdomBuilder.place_building(player, tile, :house, {5, 5})
      {:error, :insufficient_resources}
  """
  @spec place_building(Player.t(), Tile.t(), Building.type(), {integer(), integer()}) ::
          build_result()
  def place_building(player, tile, building_type, location) do
    with :ok <- validate_terrain(tile),
         :ok <- validate_tile_available(tile),
         :ok <- validate_building_type(building_type),
         :ok <- validate_resources(player, building_type) do
      building = create_building(building_type, location)
      updated_player = deduct_resources(player, building_type)
      updated_player = add_building_to_player(updated_player, building)

      {:ok, {updated_player, building}}
    end
  end

  @doc """
  Advances construction progress for a building.

  Returns the updated building with increased construction progress.

  ## Examples

      iex> building = %Building{id: "b1", type: :house, construction_progress: 50}
      iex> KingdomBuilder.advance_construction(building, 1)
      %Building{id: "b1", type: :house, construction_progress: 60}
  """
  @spec advance_construction(Building.t(), integer()) :: Building.t()
  def advance_construction(building, ticks \\ 1) do
    rate = @construction_rates[building.type] || 10
    new_progress = min(building.construction_progress + rate * ticks, 100)
    %{building | construction_progress: new_progress}
  end

  @doc """
  Checks if construction is complete.

  ## Examples

      iex> building = %Building{construction_progress: 100}
      iex> KingdomBuilder.construction_complete?(building)
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

      iex> player = %Player{resources: %{wood: 10, stone: 5, food: 0}}
      iex> building = %Building{type: :house, construction_progress: 30}
      iex> KingdomBuilder.cancel_construction(player, building)
      {:ok, %Player{resources: %{wood: 35, stone: 15, food: 0}}}
  """
  @spec cancel_construction(Player.t(), Building.t()) :: {:ok, Player.t()}
  def cancel_construction(player, building) do
    refund_percentage = if building.construction_progress < 50, do: 0.5, else: 0.0
    refunded_player = refund_resources(player, building.type, refund_percentage)
    updated_player = remove_building_from_player(refunded_player, building.id)

    {:ok, updated_player}
  end

  @doc """
  Checks if a building can be placed at the specified location.

  ## Examples

      iex> tile = %Tile{terrain: :water, building_id: nil}
      iex> KingdomBuilder.can_build_at?(tile, :house)
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

      iex> KingdomBuilder.get_building_cost(:house)
      %{wood: 50, stone: 20, food: 0}
  """
  @spec get_building_cost(Building.type()) :: Player.resources()
  def get_building_cost(building_type) do
    @building_costs[building_type] || %{wood: 0, stone: 0, food: 0}
  end

  @doc """
  Gets the construction rate (progress per tick) for a building type.
  """
  @spec get_construction_rate(Building.type()) :: integer()
  def get_construction_rate(building_type) do
    @construction_rates[building_type] || 10
  end

  # Private Functions

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

  @spec validate_resources(Player.t(), Building.type()) :: validation_result()
  defp validate_resources(player, building_type) do
    cost = @building_costs[building_type]

    has_resources? =
      Enum.all?(cost, fn {resource, amount} ->
        Map.get(player.resources, resource, 0) >= amount
      end)

    if has_resources?, do: :ok, else: {:error, :insufficient_resources}
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

  @spec deduct_resources(Player.t(), Building.type()) :: Player.t()
  defp deduct_resources(player, building_type) do
    cost = @building_costs[building_type]

    updated_resources =
      Enum.reduce(cost, player.resources, fn {resource, amount}, acc ->
        Map.update!(acc, resource, &(&1 - amount))
      end)

    %{player | resources: updated_resources}
  end

  @spec refund_resources(Player.t(), Building.type(), float()) :: Player.t()
  defp refund_resources(player, building_type, percentage) do
    cost = @building_costs[building_type]

    updated_resources =
      Enum.reduce(cost, player.resources, fn {resource, amount}, acc ->
        refund_amount = floor(amount * percentage)
        Map.update!(acc, resource, &(&1 + refund_amount))
      end)

    %{player | resources: updated_resources}
  end

  @spec add_building_to_player(Player.t(), Building.t()) :: Player.t()
  defp add_building_to_player(player, building) do
    %{player | buildings: Map.put(player.buildings, building.id, building)}
  end

  @spec remove_building_from_player(Player.t(), String.t()) :: Player.t()
  defp remove_building_from_player(player, building_id) do
    %{player | buildings: Map.delete(player.buildings, building_id)}
  end

  @spec generate_building_id() :: String.t()
  defp generate_building_id do
    "building_#{:erlang.unique_integer([:positive, :monotonic])}"
  end
end
