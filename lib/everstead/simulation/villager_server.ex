defmodule EverStead.Simulation.VillagerServer do
  @moduledoc """
  GenServer managing individual villager behavior and job execution.

  Each VillagerServer maintains a villager's state, current job, and processes
  game tick events to update the villager's actions. Villagers can:
  - Gather resources (wood, stone, food)
  - Build and work on construction projects
  - Move between locations
  - Rest and recover

  The server is registered in the VillagerRegistry using the villager's ID.
  """
  use GenServer
  require Logger

  alias EverStead.Entities.World.Kingdom.Villager
  alias EverStead.Entities.World.Kingdom.Job
  alias EverStead.World

  @gathering_rates %{wood: 5, stone: 3, food: 8}
  @movement_speed 1

  @type init_arg :: {String.t(), String.t(), String.t()}

  # Client API

  @doc """
  Starts a villager server process.

  ## Parameters
  - `{villager_id, villager_name, player_id}` - Tuple containing IDs and name

  The server is registered via the VillagerRegistry using the villager ID.
  """
  @spec start_link(init_arg()) :: GenServer.on_start()
  def start_link({villager_id, villager_name, player_id}) do
    GenServer.start_link(__MODULE__, {villager_id, villager_name, player_id},
      name: via_tuple(villager_id)
    )
  end

  @doc """
  Assigns a job to the villager.

  ## Parameters
  - `villager_id` - The ID of the villager
  - `job` - The Job struct to assign

  ## Examples

      iex> job = %Job{id: "j1", type: :gather, target: %Resource{type: :wood}}
      iex> VillagerServer.assign_job("v1", job)
      :ok
  """
  @spec assign_job(String.t(), Job.t()) :: :ok
  def assign_job(villager_id, job) do
    GenServer.cast(via_tuple(villager_id), {:assign_job, job})
  end

  @doc """
  Gets the current state of the villager.

  ## Examples

      iex> VillagerServer.get_state("v1")
      %Villager{id: "v1", name: "Bob", state: :working, ...}
  """
  @spec get_state(String.t()) :: Villager.t()
  def get_state(villager_id) do
    GenServer.call(via_tuple(villager_id), :get_state)
  end

  @doc """
  Cancels the villager's current job and returns them to idle state.

  ## Examples

      iex> VillagerServer.cancel_job("v1")
      :ok
  """
  @spec cancel_job(String.t()) :: :ok
  def cancel_job(villager_id) do
    GenServer.cast(via_tuple(villager_id), :cancel_job)
  end

  # Server Callbacks

  @impl true
  def init({villager_id, villager_name, player_id}) do
    villager = %Villager{
      id: villager_id,
      name: villager_name,
      state: :idle,
      profession: nil,
      location: {0, 0},
      inventory: %{}
    }

    state = %{
      villager: villager,
      player_id: player_id,
      current_job: nil,
      work_progress: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.villager, state}
  end

  @impl true
  def handle_cast({:assign_job, job}, state) do
    Logger.info("Villager #{state.villager.id} assigned job: #{job.type}")

    updated_villager = %{state.villager | state: :working}

    new_state = %{
      state
      | villager: updated_villager,
        current_job: job,
        work_progress: 0
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:cancel_job, state) do
    Logger.info("Villager #{state.villager.id} job cancelled")

    updated_villager = %{state.villager | state: :idle}

    new_state = %{
      state
      | villager: updated_villager,
        current_job: nil,
        work_progress: 0
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = process_tick(state)
    {:noreply, new_state}
  end

  # Private Functions

  defp via_tuple(villager_id) do
    {:via, Registry, {EverStead.VillagerRegistry, villager_id}}
  end

  @spec process_tick(map()) :: map()
  defp process_tick(%{current_job: nil} = state) do
    # Idle villager - do nothing
    state
  end

  defp process_tick(%{current_job: %Job{type: :gather}} = state) do
    process_gathering(state)
  end

  defp process_tick(%{current_job: %Job{type: :build}} = state) do
    process_building(state)
  end

  defp process_tick(%{current_job: %Job{type: :move}} = state) do
    process_movement(state)
  end

  @spec process_gathering(map()) :: map()
  defp process_gathering(state) do
    job = state.current_job
    resource_type = job.target.type
    base_rate = Map.get(@gathering_rates, resource_type, 5)

    # Apply seasonal multipliers (you can get season from WorldServer in real implementation)
    # For now, using base rate
    gathered = base_rate

    updated_inventory =
      Map.update(state.villager.inventory, resource_type, gathered, &(&1 + gathered))

    updated_villager = %{state.villager | inventory: updated_inventory}

    Logger.debug(
      "Villager #{state.villager.id} gathered #{gathered} #{resource_type} (total: #{updated_inventory[resource_type]})"
    )

    %{state | villager: updated_villager}
  end

  @spec process_gathering_with_season(map(), atom()) :: map()
  def process_gathering_with_season(state, season) do
    job = state.current_job
    resource_type = job.target.type
    base_rate = Map.get(@gathering_rates, resource_type, 5)

    # Apply seasonal multiplier
    multiplier =
      case resource_type do
        :food -> World.farming_multiplier(season)
        _ -> World.resource_multiplier(season)
      end

    gathered = floor(base_rate * multiplier)

    updated_inventory =
      Map.update(state.villager.inventory, resource_type, gathered, &(&1 + gathered))

    updated_villager = %{state.villager | inventory: updated_inventory}

    Logger.debug(
      "Villager #{state.villager.id} gathered #{gathered} #{resource_type} in #{season} (total: #{updated_inventory[resource_type]})"
    )

    %{state | villager: updated_villager}
  end

  @spec process_building(map()) :: map()
  defp process_building(state) do
    # Building progress is handled by KingdomBuilder
    # Here we just track that the villager is working
    new_progress = state.work_progress + 1

    Logger.debug(
      "Villager #{state.villager.id} working on construction (progress: #{new_progress})"
    )

    %{state | work_progress: new_progress}
  end

  @spec process_movement(map()) :: map()
  defp process_movement(state) do
    job = state.current_job
    current_loc = state.villager.location
    target_loc = get_target_location(job.target)

    if current_loc == target_loc do
      # Reached destination
      Logger.info("Villager #{state.villager.id} reached destination #{inspect(target_loc)}")

      updated_villager = %{state.villager | state: :idle, location: target_loc}

      %{state | villager: updated_villager, current_job: nil, work_progress: 0}
    else
      # Move towards target
      new_location = move_towards(current_loc, target_loc)
      updated_villager = %{state.villager | location: new_location, state: :moving}

      Logger.debug(
        "Villager #{state.villager.id} moving: #{inspect(current_loc)} -> #{inspect(new_location)}"
      )

      %{state | villager: updated_villager}
    end
  end

  @spec get_target_location(Job.target()) :: {integer(), integer()}
  defp get_target_location(%{location: location}), do: location
  defp get_target_location(_), do: {0, 0}

  @spec move_towards({integer(), integer()}, {integer(), integer()}) :: {integer(), integer()}
  defp move_towards({x1, y1}, {x2, y2}) do
    speed = @movement_speed
    dx = clamp(x2 - x1, -speed, speed)
    dy = clamp(y2 - y1, -speed, speed)
    {x1 + dx, y1 + dy}
  end

  @spec clamp(integer(), integer(), integer()) :: integer()
  defp clamp(value, min_val, max_val) do
    value
    |> max(min_val)
    |> min(max_val)
  end

  @doc """
  Gets the resource gathering rate for a resource type.

  ## Examples

      iex> VillagerServer.get_gathering_rate(:wood)
      5
  """
  @spec get_gathering_rate(atom()) :: integer()
  def get_gathering_rate(resource_type) do
    Map.get(@gathering_rates, resource_type, 5)
  end

  @doc """
  Gets the movement speed (tiles per tick).

  ## Examples

      iex> VillagerServer.get_movement_speed()
      1
  """
  @spec get_movement_speed() :: integer()
  def get_movement_speed, do: @movement_speed
end
