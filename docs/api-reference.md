# Everstead API Reference

This document provides a comprehensive reference for all public APIs in the Everstead game.

## Table of Contents

1. [World Server API](#world-server-api)
2. [Player System API](#player-system-api)
3. [Villager System API](#villager-system-api)
4. [Job Management API](#job-management-api)
5. [Kingdom Management API](#kingdom-management-api)
6. [Building System API](#building-system-api)
7. [World Context API](#world-context-api)
8. [Utility Modules API](#utility-modules-api)
9. [Entity Schemas](#entity-schemas)

## World Server API

### EverStead.Simulation.World.Server

The central world simulation server that manages time progression and seasons.

#### Functions

##### `start_link/1`

```elixir
@spec start_link(term()) :: GenServer.on_start()
```

Starts the world server process.

**Parameters:**
- `_` - Ignored argument

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

**Example:**
```elixir
{:ok, pid} = EverStead.Simulation.World.Server.start_link(%{})
```

##### `get_season/0`

```elixir
@spec get_season() :: Season.t()
```

Gets the current season information.

**Returns:**
- `%Season{}` - Current season with ticks elapsed and year

**Example:**
```elixir
season = EverStead.Simulation.World.Server.get_season()
# %Season{current: :spring, ticks_elapsed: 42, year: 1}
```

##### `get_state/0`

```elixir
@spec get_state() :: map()
```

Gets the current world state including season and tick count.

**Returns:**
- `%{season: %Season{}, total_ticks: integer()}` - World state

**Example:**
```elixir
state = EverStead.Simulation.World.Server.get_state()
# %{season: %Season{current: :spring, ticks_elapsed: 42, year: 1}, total_ticks: 150}
```

## Player System API

### EverStead.Simulation.Player.Supervisor

Dynamic supervisor for managing player server processes.

#### Functions

##### `start_link/1`

```elixir
@spec start_link(term()) :: Supervisor.on_start()
```

Starts the player supervisor.

**Parameters:**
- `_` - Ignored argument

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

##### `start_player/2`

```elixir
@spec start_player(String.t(), String.t()) :: DynamicSupervisor.on_start_child()
```

Starts a new player server process.

**Parameters:**
- `player_id` - Unique identifier for the player
- `name` - Display name for the player

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

**Example:**
```elixir
{:ok, pid} = EverStead.Simulation.Player.Supervisor.start_player("player1", "Alice")
```

##### `broadcast_tick/0`

```elixir
@spec broadcast_tick() :: :ok
```

Broadcasts a tick event to all registered player servers.

**Returns:**
- `:ok` - Always succeeds

### EverStead.Simulation.Player.Server

GenServer managing individual player state and game logic.

#### Functions

##### `start_link/1`

```elixir
@spec start_link({String.t(), String.t()}) :: GenServer.on_start()
```

Starts a player server process.

**Parameters:**
- `{id, name}` - Tuple containing the player ID and display name

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

##### `get_state/1`

```elixir
@spec get_state(String.t()) :: Player.t()
```

Gets the current player state.

**Parameters:**
- `player_id` - The ID of the player

**Returns:**
- `%Player{}` - Current player state

**Example:**
```elixir
player = EverStead.Simulation.Player.Server.get_state("player1")
```

## Villager System API

### EverStead.Simulation.Kingdom.Villager.Supervisor

Dynamic supervisor for managing villager server processes.

#### Functions

##### `start_link/1`

```elixir
@spec start_link(term()) :: Supervisor.on_start()
```

Starts the villager supervisor.

**Parameters:**
- `_` - Ignored argument

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

##### `start_villager/3`

```elixir
@spec start_villager(String.t(), String.t(), String.t()) :: DynamicSupervisor.on_start_child()
```

Starts a new villager server process.

**Parameters:**
- `villager_id` - Unique identifier for the villager
- `villager_name` - Display name for the villager
- `player_id` - ID of the player who owns this villager

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

**Example:**
```elixir
{:ok, pid} = EverStead.Simulation.Kingdom.Villager.Supervisor.start_villager("villager1", "Bob", "player1")
```

##### `broadcast_tick/0`

```elixir
@spec broadcast_tick() :: :ok
```

Broadcasts a tick event to all registered villager servers.

**Returns:**
- `:ok` - Always succeeds

### EverStead.Simulation.Kingdom.Villager.Server

GenServer managing individual villager behavior and job execution.

#### Functions

##### `start_link/1`

```elixir
@spec start_link({String.t(), String.t(), String.t()}) :: GenServer.on_start()
```

Starts a villager server process.

**Parameters:**
- `{villager_id, villager_name, player_id}` - Tuple containing IDs and name

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

##### `assign_job/2`

```elixir
@spec assign_job(String.t(), Job.t()) :: :ok
```

Assigns a job to the villager.

**Parameters:**
- `villager_id` - The ID of the villager
- `job` - The Job struct to assign

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
job = %Job{id: "j1", type: :gather, target: %{type: :wood, location: {10, 10}}}
EverStead.Simulation.Kingdom.Villager.Server.assign_job("villager1", job)
```

##### `get_state/1`

```elixir
@spec get_state(String.t()) :: Villager.t()
```

Gets the current state of the villager.

**Parameters:**
- `villager_id` - The ID of the villager

**Returns:**
- `%Villager{}` - Current villager state

**Example:**
```elixir
villager = EverStead.Simulation.Kingdom.Villager.Server.get_state("villager1")
```

##### `cancel_job/1`

```elixir
@spec cancel_job(String.t()) :: :ok
```

Cancels the villager's current job and returns them to idle state.

**Parameters:**
- `villager_id` - The ID of the villager

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
EverStead.Simulation.Kingdom.Villager.Server.cancel_job("villager1")
```

##### `get_gathering_rate/1`

```elixir
@spec get_gathering_rate(atom()) :: integer()
```

Gets the resource gathering rate for a resource type.

**Parameters:**
- `resource_type` - The type of resource (:wood, :stone, :food)

**Returns:**
- `integer()` - Gathering rate per tick

**Example:**
```elixir
rate = EverStead.Simulation.Kingdom.Villager.Server.get_gathering_rate(:wood)
# 5
```

##### `get_movement_speed/0`

```elixir
@spec get_movement_speed() :: integer()
```

Gets the movement speed (tiles per tick).

**Returns:**
- `integer()` - Movement speed

**Example:**
```elixir
speed = EverStead.Simulation.Kingdom.Villager.Server.get_movement_speed()
# 1
```

## Job Management API

### EverStead.Simulation.Kingdom.JobManager

Manages job assignment and distribution for villagers.

#### Functions

##### `start_link/1`

```elixir
@spec start_link(term()) :: GenServer.on_start()
```

Starts the job manager server.

**Parameters:**
- `_` - Ignored argument

**Returns:**
- `{:ok, pid}` - On success
- `{:error, reason}` - On failure

##### `add_job/2`

```elixir
@spec add_job(Job.t(), priority()) :: :ok
```

Adds a job to the queue with a specified priority.

**Parameters:**
- `job` - The Job struct to add
- `priority` - Priority level (`:critical`, `:high`, `:normal`, `:low`)

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
job = %Job{id: "j1", type: :gather, target: %{type: :wood, location: {10, 10}}}
EverStead.Simulation.Kingdom.JobManager.add_job(job, :high)
```

##### `remove_job/1`

```elixir
@spec remove_job(String.t()) :: :ok
```

Removes a job from the queue by ID.

**Parameters:**
- `job_id` - The ID of the job to remove

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
EverStead.Simulation.Kingdom.JobManager.remove_job("j1")
```

##### `assign_jobs/1`

```elixir
@spec assign_jobs(%{String.t() => Villager.t()}) :: :ok
```

Assigns jobs to idle villagers from the job queue.

**Parameters:**
- `villagers` - Map of villager IDs to villager structs

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
villagers = %{"villager1" => %Villager{id: "villager1", state: :idle}}
EverStead.Simulation.Kingdom.JobManager.assign_jobs(villagers)
```

##### `complete_job/2`

```elixir
@spec complete_job(String.t(), String.t()) :: :ok
```

Marks a job as completed and removes it from active tracking.

**Parameters:**
- `job_id` - The ID of the completed job
- `villager_id` - The ID of the villager who completed it

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
EverStead.Simulation.Kingdom.JobManager.complete_job("j1", "villager1")
```

##### `get_state/0`

```elixir
@spec get_state() :: map()
```

Gets the current state of the job manager.

**Returns:**
- `%{job_queue: [...], active_jobs: %{...}, stats: %{...}}` - Job manager state

**Example:**
```elixir
state = EverStead.Simulation.Kingdom.JobManager.get_state()
```

##### `clear_all_jobs/0`

```elixir
@spec clear_all_jobs() :: :ok
```

Clears all jobs from the queue and active tracking.

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
EverStead.Simulation.Kingdom.JobManager.clear_all_jobs()
```

##### `check_stale_jobs/0`

```elixir
@spec check_stale_jobs() :: :ok
```

Checks for stale jobs where the assigned villager is no longer alive.

**Returns:**
- `:ok` - Always succeeds

**Example:**
```elixir
EverStead.Simulation.Kingdom.JobManager.check_stale_jobs()
```

## Kingdom Management API

### EverStead.Kingdom

Context module for kingdom operations including resource management.

#### Functions

##### `get_resource_amount/2`

```elixir
@spec get_resource_amount(Kingdom.t(), atom()) :: integer()
```

Gets the amount of a specific resource type in the kingdom.

**Parameters:**
- `kingdom` - The kingdom struct
- `resource_type` - The type of resource (:wood, :stone, :food)

**Returns:**
- `integer()` - Amount of the resource (0 if not found)

**Example:**
```elixir
amount = EverStead.Kingdom.get_resource_amount(kingdom, :wood)
# 100
```

##### `has_resources?/2`

```elixir
@spec has_resources?(Kingdom.t(), map()) :: boolean()
```

Checks if the kingdom has enough resources to cover the given costs.

**Parameters:**
- `kingdom` - The kingdom struct
- `costs` - Map of resource types to required amounts

**Returns:**
- `boolean()` - True if all resources are available

**Example:**
```elixir
has_enough = EverStead.Kingdom.has_resources?(kingdom, %{wood: 50, stone: 20})
# true
```

##### `deduct_resources/2`

```elixir
@spec deduct_resources(Kingdom.t(), map()) :: Kingdom.t()
```

Deducts resources from the kingdom.

**Parameters:**
- `kingdom` - The kingdom struct
- `costs` - Map of resource types to amounts to deduct

**Returns:**
- `%Kingdom{}` - Updated kingdom with reduced resources

**Example:**
```elixir
updated_kingdom = EverStead.Kingdom.deduct_resources(kingdom, %{wood: 50})
```

##### `add_resources/2`

```elixir
@spec add_resources(Kingdom.t(), map()) :: Kingdom.t()
```

Adds resources to the kingdom.

**Parameters:**
- `kingdom` - The kingdom struct
- `additions` - Map of resource types to amounts to add

**Returns:**
- `%Kingdom{}` - Updated kingdom with increased resources

**Example:**
```elixir
updated_kingdom = EverStead.Kingdom.add_resources(kingdom, %{wood: 100})
```

## Building System API

### EverStead.Simulation.Kingdom.Builder

Handles kingdom building logic including placement, validation, and construction.

#### Functions

##### `place_building/4`

```elixir
@spec place_building(Player.t(), Tile.t(), Building.type(), {integer(), integer()}) :: build_result()
```

Places a new building at the specified location.

**Parameters:**
- `player` - The player struct
- `tile` - The tile where the building will be placed
- `building_type` - The type of building (:house, :farm, :lumberyard, :storage)
- `location` - The coordinates where the building will be placed

**Returns:**
- `{:ok, {Player.t(), Building.t()}}` - On success
- `{:error, atom()}` - On failure

**Example:**
```elixir
tile = %Tile{terrain: :grass, building_id: nil}
{:ok, {updated_player, building}} = EverStead.Simulation.Kingdom.Builder.place_building(player, tile, :house, {5, 5})
```

##### `advance_construction/2`

```elixir
@spec advance_construction(Building.t(), integer()) :: Building.t()
```

Advances construction progress for a building.

**Parameters:**
- `building` - The building struct
- `ticks` - Number of ticks to advance (default: 1)

**Returns:**
- `%Building{}` - Updated building with increased progress

**Example:**
```elixir
advanced_building = EverStead.Simulation.Kingdom.Builder.advance_construction(building, 1)
```

##### `advance_construction_with_season/3`

```elixir
@spec advance_construction_with_season(Building.t(), atom(), integer()) :: Building.t()
```

Advances construction progress with seasonal modifiers.

**Parameters:**
- `building` - The building struct
- `season` - Current season (:spring, :summer, :fall, :winter)
- `ticks` - Number of ticks to advance (default: 1)

**Returns:**
- `%Building{}` - Updated building with increased progress

**Example:**
```elixir
advanced_building = EverStead.Simulation.Kingdom.Builder.advance_construction_with_season(building, :summer, 1)
```

##### `construction_complete?/1`

```elixir
@spec construction_complete?(Building.t()) :: boolean()
```

Checks if construction is complete.

**Parameters:**
- `building` - The building struct

**Returns:**
- `boolean()` - True if construction is complete

**Example:**
```elixir
is_complete = EverStead.Simulation.Kingdom.Builder.construction_complete?(building)
```

##### `cancel_construction/2`

```elixir
@spec cancel_construction(Player.t(), Building.t()) :: {:ok, Player.t()}
```

Cancels building construction and refunds resources.

**Parameters:**
- `player` - The player struct
- `building` - The building to cancel

**Returns:**
- `{:ok, Player.t()}` - Updated player with refunded resources

**Example:**
```elixir
{:ok, updated_player} = EverStead.Simulation.Kingdom.Builder.cancel_construction(player, building)
```

##### `can_build_at?/2`

```elixir
@spec can_build_at?(Tile.t(), Building.type()) :: validation_result()
```

Checks if a building can be placed at the specified location.

**Parameters:**
- `tile` - The tile struct
- `building_type` - The type of building

**Returns:**
- `:ok` - If building can be placed
- `{:error, atom()}` - If building cannot be placed

**Example:**
```elixir
result = EverStead.Simulation.Kingdom.Builder.can_build_at?(tile, :house)
```

##### `get_building_cost/1`

```elixir
@spec get_building_cost(atom()) :: map()
```

Gets the resource cost for a building type.

**Parameters:**
- `building_type` - The type of building

**Returns:**
- `map()` - Map of resource types to costs

**Example:**
```elixir
cost = EverStead.Simulation.Kingdom.Builder.get_building_cost(:house)
# %{wood: 50, stone: 20, food: 0}
```

##### `get_construction_rate/1`

```elixir
@spec get_construction_rate(atom()) :: integer()
```

Gets the construction rate (progress per tick) for a building type.

**Parameters:**
- `building_type` - The type of building

**Returns:**
- `integer()` - Construction rate per tick

**Example:**
```elixir
rate = EverStead.Simulation.Kingdom.Builder.get_construction_rate(:house)
# 10
```

## World Context API

### EverStead.World

Context module for world-related operations including season progression and multipliers.

#### Functions

##### `season_duration/0`

```elixir
@spec season_duration() :: integer()
```

Returns the duration of a season in ticks.

**Returns:**
- `integer()` - Season duration in ticks

**Example:**
```elixir
duration = EverStead.World.season_duration()
# 60
```

##### `next_season/1`

```elixir
@spec next_season(atom()) :: atom()
```

Returns the next season in the cycle.

**Parameters:**
- `current_season` - Current season (:spring, :summer, :fall, :winter)

**Returns:**
- `atom()` - Next season

**Example:**
```elixir
next = EverStead.World.next_season(:spring)
# :summer
```

##### `tick_season/1`

```elixir
@spec tick_season(Season.t()) :: Season.t()
```

Advances the season by one tick.

**Parameters:**
- `season` - Current season struct

**Returns:**
- `%Season{}` - Updated season struct

**Example:**
```elixir
new_season = EverStead.World.tick_season(season)
```

##### `resource_multiplier/1`

```elixir
@spec resource_multiplier(atom()) :: float()
```

Returns a float multiplier for resource gathering based on season.

**Parameters:**
- `season` - Current season

**Returns:**
- `float()` - Resource gathering multiplier

**Example:**
```elixir
multiplier = EverStead.World.resource_multiplier(:summer)
# 1.2
```

##### `farming_multiplier/1`

```elixir
@spec farming_multiplier(atom()) :: float()
```

Returns a float multiplier for farming based on season.

**Parameters:**
- `season` - Current season

**Returns:**
- `float()` - Farming multiplier

**Example:**
```elixir
multiplier = EverStead.World.farming_multiplier(:summer)
# 1.5
```

##### `construction_multiplier/1`

```elixir
@spec construction_multiplier(atom()) :: float()
```

Returns a float multiplier for construction speed based on season.

**Parameters:**
- `season` - Current season

**Returns:**
- `float()` - Construction multiplier

**Example:**
```elixir
multiplier = EverStead.World.construction_multiplier(:summer)
# 1.2
```

##### `season_to_string/1`

```elixir
@spec season_to_string(atom()) :: String.t()
```

Returns the season as a human-readable string.

**Parameters:**
- `season` - Season atom

**Returns:**
- `String.t()` - Human-readable season name

**Example:**
```elixir
season_string = EverStead.World.season_to_string(:spring)
# "Spring"
```

## Utility Modules API

### EverStead.GameMonitor

Utility module for monitoring game state and resource gathering progress.

#### Functions

##### `watch_resources/2`

```elixir
@spec watch_resources(String.t(), [String.t()]) :: :ok
```

Monitors and displays comprehensive game state for a player and their villagers.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `villager_ids` - List of villager IDs to monitor

**Returns:**
- `:ok` - Always returns :ok

**Example:**
```elixir
EverStead.GameMonitor.watch_resources("player1", ["villager1", "villager2"])
```

##### `get_game_summary/2`

```elixir
@spec get_game_summary(String.t(), [String.t()]) :: map()
```

Gets a summary of the current game state as a map.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `villager_ids` - List of villager IDs to monitor

**Returns:**
- `map()` - Summary of game state including kingdom resources, villagers, job manager, and world state

**Example:**
```elixir
summary = EverStead.GameMonitor.get_game_summary("player1", ["villager1"])
# Returns:
# %{
#   kingdom_resources: [%Resource{type: :wood, amount: 0}, ...],
#   villagers: [...],
#   job_manager: %{...},
#   world_state: %{...}
# }
```

##### `monitor_gathering/3`

```elixir
@spec monitor_gathering(String.t(), [String.t()], integer()) :: :ok
```

Monitors resource gathering progress and displays updates.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `villager_ids` - List of villager IDs to monitor
- `duration_seconds` - How long to monitor (default: 10)

**Returns:**
- `:ok` - Always returns :ok

**Example:**
```elixir
EverStead.GameMonitor.monitor_gathering("player1", ["villager1"], 5)
```

##### `has_resources?/2`

```elixir
@spec has_resources?(String.t(), map()) :: boolean()
```

Checks if a player has enough resources for a specific cost.

**Parameters:**
- `player_id` - The ID of the player to check
- `costs` - Map of resource types to required amounts

**Returns:**
- `boolean()` - True if player has enough resources

**Example:**
```elixir
EverStead.GameMonitor.has_resources?("player1", %{wood: 50, stone: 20})
# => false
```

##### `get_resources/1`

```elixir
@spec get_resources(String.t()) :: [Resource.t()]
```

Gets the current resource amounts for a player.

**Parameters:**
- `player_id` - The ID of the player to check

**Returns:**
- `[Resource.t()]` - List of Resource structs

**Example:**
```elixir
resources = EverStead.GameMonitor.get_resources("player1")
# Returns: [%Resource{type: :wood, amount: 0}, ...]
```

##### `status_report/2`

```elixir
@spec status_report(String.t(), [String.t()]) :: :ok
```

Displays a formatted status report for a player and their villagers.

**Parameters:**
- `player_id` - The ID of the player to report on
- `villager_ids` - List of villager IDs to include in report

**Returns:**
- `:ok` - Always returns :ok

**Example:**
```elixir
EverStead.GameMonitor.status_report("player1", ["villager1"])
```

### EverStead.ResourceWaiter

Utility module for waiting for resources to accumulate in the game.

#### Functions

##### `wait_for_resources/3`

```elixir
@spec wait_for_resources(String.t(), map(), integer()) :: :ok | :timeout
```

Waits for a player to have enough resources for the specified costs.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `required_resources` - Map of resource types to required amounts
- `max_ticks` - Maximum number of ticks to wait (default: 60)

**Returns:**
- `:ok` - When resources are available
- `:timeout` - When max_ticks is reached without sufficient resources

**Example:**
```elixir
EverStead.ResourceWaiter.wait_for_resources("player1", %{wood: 50, stone: 20})
# => :ok
```

##### `wait_with_progress/4`

```elixir
@spec wait_with_progress(String.t(), map(), integer(), function()) :: :ok | :timeout
```

Waits for resources with a progress callback function.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `required_resources` - Map of resource types to required amounts
- `max_ticks` - Maximum number of ticks to wait
- `progress_callback` - Function called each tick with current resources

**Returns:**
- `:ok` - When resources are available
- `:timeout` - When max_ticks is reached

**Example:**
```elixir
callback = fn resources, tick -> IO.puts("Tick #{tick}: #{inspect(resources)}") end
EverStead.ResourceWaiter.wait_with_progress("player1", %{wood: 50}, 10, callback)
```

##### `wait_for_resource/4`

```elixir
@spec wait_for_resource(String.t(), atom(), integer(), integer()) :: :ok | :timeout
```

Waits for a specific resource amount with detailed progress reporting.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `resource_type` - The type of resource to wait for (:wood, :stone, :food)
- `required_amount` - The amount needed
- `max_ticks` - Maximum number of ticks to wait (default: 60)

**Returns:**
- `:ok` - When the resource amount is reached
- `:timeout` - When max_ticks is reached

**Example:**
```elixir
EverStead.ResourceWaiter.wait_for_resource("player1", :wood, 100, 30)
```

##### `wait_for_multiple_resources/3`

```elixir
@spec wait_for_multiple_resources(String.t(), map(), integer()) :: :ok | :timeout
```

Waits for multiple resources with a combined progress report.

**Parameters:**
- `player_id` - The ID of the player to monitor
- `required_resources` - Map of resource types to required amounts
- `max_ticks` - Maximum number of ticks to wait (default: 60)

**Returns:**
- `:ok` - When all resources are available
- `:timeout` - When max_ticks is reached

**Example:**
```elixir
EverStead.ResourceWaiter.wait_for_multiple_resources("player1", %{wood: 50, stone: 20}, 30)
```

##### `get_progress/2`

```elixir
@spec get_progress(String.t(), map()) :: float()
```

Gets the current progress towards required resources as a percentage.

**Parameters:**
- `player_id` - The ID of the player to check
- `required_resources` - Map of resource types to required amounts

**Returns:**
- `float()` - Progress percentage (0.0 to 1.0)

**Example:**
```elixir
progress = EverStead.ResourceWaiter.get_progress("player1", %{wood: 100, stone: 50})
# => 0.3
```

## Entity Schemas

### EverStead.Entities.Player

Player entity representing a kingdom owner.

```elixir
%Player{
  id: String.t(),
  name: String.t(),
  kingdom: Kingdom.t()
}
```

### EverStead.Entities.World.Kingdom

Kingdom entity containing resources, villagers, and buildings.

```elixir
%Kingdom{
  id: String.t(),
  name: String.t(),
  villagers: [Villager.t()],
  buildings: [Building.t()],
  resources: %{wood: integer(), stone: integer(), food: integer()}
}
```

### EverStead.Entities.World.Kingdom.Villager

Villager entity representing a worker.

```elixir
%Villager{
  id: String.t(),
  name: String.t(),
  state: :idle | :working | :moving,
  profession: atom() | nil,
  location: {integer(), integer()},
  inventory: map()
}
```

### EverStead.Entities.World.Kingdom.Building

Building entity representing a structure.

```elixir
%Building{
  id: String.t(),
  type: :house | :farm | :lumberyard | :storage,
  location: {integer(), integer()},
  construction_progress: integer(),
  hp: integer()
}
```

### EverStead.Entities.World.Kingdom.Job

Job entity representing a task for a villager.

```elixir
%Job{
  id: String.t(),
  type: :gather | :build | :move,
  status: :pending | :in_progress | :done,
  target: map(),
  assigned_villager_id: String.t() | nil
}
```

### EverStead.Entities.World.Season

Season entity representing the current season and time.

```elixir
%Season{
  current: :spring | :summer | :fall | :winter,
  ticks_elapsed: integer(),
  year: integer()
}
```

### EverStead.Entities.World.Tile

Tile entity representing a location on the map.

```elixir
%Tile{
  terrain: :grass | :water | :mountain,
  building_id: String.t() | nil
}
```

## Error Handling

### Common Error Types

- `:insufficient_resources` - Not enough resources for an operation
- `:invalid_terrain` - Building cannot be placed on this terrain
- `:tile_occupied` - Location already has a building
- `:invalid_building_type` - Unknown building type
- `:no_jobs` - No jobs available for assignment

### Error Handling Patterns

```elixir
# Pattern matching for success/error
case EverStead.Simulation.Kingdom.Builder.place_building(player, tile, :house, {5, 5}) do
  {:ok, {updated_player, building}} ->
    # Handle success
    IO.puts("Building placed successfully!")
  
  {:error, :insufficient_resources} ->
    # Handle specific error
    IO.puts("Not enough resources!")
  
  {:error, reason} ->
    # Handle other errors
    IO.puts("Error: #{reason}")
end
```

This API reference provides comprehensive documentation for all public functions in the Everstead game. Use this as a reference when developing with the game's APIs.