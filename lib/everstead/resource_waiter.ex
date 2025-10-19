defmodule EverStead.ResourceWaiter do
  @moduledoc """
  Utility module for waiting for resources to accumulate in the game.

  Provides functions to wait for specific resource amounts, monitor
  resource gathering progress, and handle timeouts gracefully.
  """

  require Logger

  alias EverStead.Simulation.Player.Server, as: PlayerServer
  alias EverStead.Kingdom

  @doc """
  Waits for a player to have enough resources for the specified costs.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `required_resources` - Map of resource types to required amounts
  - `max_ticks` - Maximum number of ticks to wait (default: 60)

  ## Returns
  - `:ok` - When resources are available
  - `:timeout` - When max_ticks is reached without sufficient resources

  ## Examples

      iex> ResourceWaiter.wait_for_resources("player1", %{wood: 50, stone: 20})
      :ok
      
      iex> ResourceWaiter.wait_for_resources("player1", %{wood: 1000}, 10)
      :timeout
  """
  @spec wait_for_resources(String.t(), map(), integer()) :: :ok | :timeout
  def wait_for_resources(player_id, required_resources, max_ticks \\ 60) do
    wait_for_resources(player_id, required_resources, max_ticks, 0)
  end

  defp wait_for_resources(_player_id, _required_resources, max_ticks, current_tick)
       when current_tick >= max_ticks do
    Logger.debug("Timeout waiting for resources after #{max_ticks} ticks")
    :timeout
  end

  defp wait_for_resources(player_id, required_resources, max_ticks, current_tick) do
    player = PlayerServer.get_state(player_id)

    if Kingdom.has_resources?(player.kingdom, required_resources) do
      Logger.debug("Resources available after #{current_tick} ticks!")
      Logger.debug("Current Resources: #{inspect(player.kingdom.resources)}")
      :ok
    else
      Logger.debug("Waiting for resources... (tick #{current_tick})")
      Logger.debug("Current Resources: #{inspect(player.kingdom.resources)}")

      # Wait 1 second (1 tick)
      Process.sleep(1000)
      wait_for_resources(player_id, required_resources, max_ticks, current_tick + 1)
    end
  end

  @doc """
  Waits for resources with a progress callback function.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `required_resources` - Map of resource types to required amounts
  - `max_ticks` - Maximum number of ticks to wait
  - `progress_callback` - Function called each tick with current resources

  ## Examples

      iex> callback = fn resources, tick -> IO.puts("Tick \#{tick}: \#{inspect(resources)}") end
      iex> ResourceWaiter.wait_with_progress("player1", %{wood: 50}, 10, callback)
      :ok
  """
  @spec wait_with_progress(String.t(), map(), integer(), function()) :: :ok | :timeout
  def wait_with_progress(player_id, required_resources, max_ticks, progress_callback) do
    wait_with_progress(player_id, required_resources, max_ticks, progress_callback, 0)
  end

  defp wait_with_progress(
         _player_id,
         _required_resources,
         max_ticks,
         _progress_callback,
         current_tick
       )
       when current_tick >= max_ticks do
    Logger.debug("Timeout waiting for resources after #{max_ticks} ticks")
    :timeout
  end

  defp wait_with_progress(
         player_id,
         required_resources,
         max_ticks,
         progress_callback,
         current_tick
       ) do
    player = PlayerServer.get_state(player_id)
    current_resources = player.kingdom.resources

    progress_callback.(current_resources, current_tick)

    if Kingdom.has_resources?(player.kingdom, required_resources) do
      Logger.debug("Resources available after #{current_tick} ticks!")
      :ok
    else
      Process.sleep(1000)

      wait_with_progress(
        player_id,
        required_resources,
        max_ticks,
        progress_callback,
        current_tick + 1
      )
    end
  end

  @doc """
  Waits for a specific resource amount with detailed progress reporting.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `resource_type` - The type of resource to wait for (:wood, :stone, :food)
  - `required_amount` - The amount needed
  - `max_ticks` - Maximum number of ticks to wait

  ## Returns
  - `:ok` - When the resource amount is reached
  - `:timeout` - When max_ticks is reached

  ## Examples

      iex> ResourceWaiter.wait_for_resource("player1", :wood, 100, 30)
      Waiting for 100 wood...
      Tick 0: 0/100 wood (0%)
      Tick 1: 5/100 wood (5%)
      ...
      :ok
  """
  @spec wait_for_resource(String.t(), atom(), integer(), integer()) :: :ok | :timeout
  def wait_for_resource(player_id, resource_type, required_amount, max_ticks \\ 60) do
    Logger.debug("Waiting for #{required_amount} #{resource_type}...")
    wait_for_resource(player_id, resource_type, required_amount, max_ticks, 0)
  end

  defp wait_for_resource(_player_id, resource_type, required_amount, max_ticks, current_tick)
       when current_tick >= max_ticks do
    Logger.debug(
      "Timeout waiting for #{required_amount} #{resource_type} after #{max_ticks} ticks"
    )

    :timeout
  end

  defp wait_for_resource(player_id, resource_type, required_amount, max_ticks, current_tick) do
    player = PlayerServer.get_state(player_id)
    current_amount = Kingdom.get_resource_amount(player.kingdom, resource_type)

    percentage =
      if required_amount > 0, do: round(current_amount / required_amount * 100), else: 100

    Logger.debug(
      "Tick #{current_tick}: #{current_amount}/#{required_amount} #{resource_type} (#{percentage}%)"
    )

    if current_amount >= required_amount do
      Logger.debug("Required amount of #{resource_type} reached after #{current_tick} ticks!")
      :ok
    else
      Process.sleep(1000)
      wait_for_resource(player_id, resource_type, required_amount, max_ticks, current_tick + 1)
    end
  end

  @doc """
  Waits for multiple resources with a combined progress report.

  ## Parameters
  - `player_id` - The ID of the player to monitor
  - `required_resources` - Map of resource types to required amounts
  - `max_ticks` - Maximum number of ticks to wait

  ## Returns
  - `:ok` - When all resources are available
  - `:timeout` - When max_ticks is reached

  ## Examples

      iex> ResourceWaiter.wait_for_multiple_resources("player1", %{wood: 50, stone: 20}, 30)
      Waiting for multiple resources...
      Tick 0: Wood: 0/50, Stone: 0/20
      ...
      :ok
  """
  @spec wait_for_multiple_resources(String.t(), map(), integer()) :: :ok | :timeout
  def wait_for_multiple_resources(player_id, required_resources, max_ticks \\ 60) do
    Logger.debug("Waiting for multiple resources...")
    wait_for_multiple_resources(player_id, required_resources, max_ticks, 0)
  end

  defp wait_for_multiple_resources(_player_id, _required_resources, max_ticks, current_tick)
       when current_tick >= max_ticks do
    Logger.debug("Timeout waiting for multiple resources after #{max_ticks} ticks")
    :timeout
  end

  defp wait_for_multiple_resources(player_id, required_resources, max_ticks, current_tick) do
    player = PlayerServer.get_state(player_id)

    resource_status =
      Enum.map(required_resources, fn {resource_type, required_amount} ->
        current_amount = Kingdom.get_resource_amount(player.kingdom, resource_type)

        "#{String.capitalize(Atom.to_string(resource_type))}: #{current_amount}/#{required_amount}"
      end)
      |> Enum.join(", ")

    Logger.debug("Tick #{current_tick}: #{resource_status}")

    if Kingdom.has_resources?(player.kingdom, required_resources) do
      Logger.debug("All required resources available after #{current_tick} ticks!")
      :ok
    else
      Process.sleep(1000)
      wait_for_multiple_resources(player_id, required_resources, max_ticks, current_tick + 1)
    end
  end

  @doc """
  Gets the current progress towards required resources as a percentage.

  ## Parameters
  - `player_id` - The ID of the player to check
  - `required_resources` - Map of resource types to required amounts

  ## Returns
  - `float()` - Progress percentage (0.0 to 1.0)

  ## Examples

      iex> ResourceWaiter.get_progress("player1", %{wood: 100, stone: 50})
      0.3
  """
  @spec get_progress(String.t(), map()) :: float()
  def get_progress(player_id, required_resources) do
    player = PlayerServer.get_state(player_id)

    progress_per_resource =
      Enum.map(required_resources, fn {resource_type, required_amount} ->
        current_amount = Kingdom.get_resource_amount(player.kingdom, resource_type)
        if required_amount > 0, do: current_amount / required_amount, else: 1.0
      end)

    # Return the minimum progress across all resources
    # If no resources are required, return 1.0 (100% complete)
    case progress_per_resource do
      [] -> 1.0
      list -> Enum.min(list, fn -> 0.0 end)
    end
  end
end
