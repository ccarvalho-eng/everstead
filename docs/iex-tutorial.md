# IEx Tutorial

## Start the Game

```bash
iex -S mix
```

## Start the Application

```elixir
Application.ensure_all_started(:everstead)
```

## Create a Player

```elixir
# Start a player supervisor with custom kingdom name (this creates both player and kingdom)
{:ok, _pid} = Everstead.Simulation.Player.Supervisor.start_link({"p1", "Alice", "The Kingdom of Eldoria"})
```

## Check Player State

```elixir
# Get full player state
state = Everstead.Simulation.Player.Server.get_state("p1")

# Check player info
state.name
state.id

# Check kingdom info
state.kingdom.name
state.kingdom.id
```

## Kingdom Overview

```elixir
# Get a complete overview of your kingdom
IO.puts("=== #{state.kingdom.name} ===")
IO.puts("Ruler: #{state.name}")
IO.puts("Population: #{length(state.kingdom.villagers)} villagers")
IO.puts("Buildings: #{length(state.kingdom.buildings)} structures")
IO.puts("Resources: #{Enum.map(state.kingdom.resources, fn r -> "#{r.type}: #{r.amount}" end) |> Enum.join(", ")}")
```

## Check Villagers

```elixir
# The kingdom starts with 5 randomly named medieval villagers
villagers = state.kingdom.villagers
IO.puts("Number of villagers: #{length(villagers)}")

# List all villagers with their professions and states
Enum.map(villagers, fn v -> 
  IO.puts("#{v.name} (#{v.profession}) - #{v.state}")
  {v.name, v.profession, v.state}
end)
```

## Check Resources

```elixir
# Check kingdom resources (starts with substantial initial resources)
resources = state.kingdom.resources
Enum.map(resources, fn r -> 
  IO.puts("#{r.type}: #{r.amount}")
  {r.type, r.amount}
end)

# Add more resources using the Kingdom context module
updated_kingdom = Everstead.Kingdom.add_resources(state.kingdom, %{wood: 50, stone: 30, food: 20})
# Note: This returns a new kingdom struct, but doesn't update the player state
```

## Check Buildings

```elixir
# Check buildings (starts with some default buildings)
buildings = state.kingdom.buildings
IO.puts("Number of buildings: #{length(buildings)}")

# List all buildings with their types, locations, and construction status
Enum.map(buildings, fn b -> 
  status = if b.construction_progress == 100, do: "Complete", else: "#{b.construction_progress}%"
  IO.puts("#{b.type} at #{inspect(b.location)} - #{status}")
  {b.type, b.location, b.construction_progress}
end)
```

## Create and Assign Jobs

### Create Jobs

```elixir
# Create different types of jobs
# 1. Gather job - collect resources
gather_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_1",
  type: :gather,
  target: %{resource: :wood, amount: 20, location: %{x: 10, y: 10}},
  status: :pending
}

# 2. Build job - construct buildings
build_job = %Everstead.Entities.World.Kingdom.Job{
  id: "build_house_1",
  type: :build,
  target: %{building_type: :house, location: %{x: 15, y: 15}},
  status: :pending
}

# 3. Move job - relocate villagers
move_job = %Everstead.Entities.World.Kingdom.Job{
  id: "move_villager_1",
  type: :move,
  target: %{destination: %{x: 20, y: 20}},
  status: :pending
}
```

### Add Jobs to Job Manager

```elixir
# Add jobs with different priorities
# Priority levels: :critical, :high, :normal, :low
job_manager_name = Everstead.Simulation.Kingdom.JobManager.Server.get_for_kingdom("p1")
GenServer.cast(job_manager_name, {:add_job, gather_job, :high})
GenServer.cast(job_manager_name, {:add_job, build_job, :normal})
GenServer.cast(job_manager_name, {:add_job, move_job, :low})

# Check job queue status (use kingdom-specific job manager)
job_manager_name = Everstead.Simulation.Kingdom.JobManager.Server.get_for_kingdom("p1")
job_manager_state = GenServer.call(job_manager_name, :get_state)
IO.puts("Jobs in queue: #{length(job_manager_state.job_queue)}")
IO.puts("Active jobs: #{map_size(job_manager_state.active_jobs)}")
```

### Assign Jobs to Villagers

```elixir
# Get all villagers for your kingdom
villagers = Everstead.Simulation.Player.Server.get_villagers("p1")

# The system automatically assigns jobs to idle villagers during each tick
# But you can also manually trigger job assignment
job_manager_name = {:via, Registry, {Everstead.KingdomRegistry, "jobmanager_p1"}}
Everstead.Simulation.Kingdom.JobManager.Server.assign_jobs(job_manager_name, villagers)

# Check villager states after assignment
villagers_after = Everstead.Simulation.Player.Server.get_villagers("p1")
Enum.map(villagers_after, fn {id, villager} -> 
  case villager.state do
    :working -> "#{villager.name} is working on a job"
    :idle -> "#{villager.name} is idle and available"
    :moving -> "#{villager.name} is moving to a location"
    :resting -> "#{villager.name} is resting"
    _ -> "#{villager.name} is #{villager.state}"
  end
end)
```

### Monitor Job Progress

```elixir
# Check individual villager job status
villager_id = "p1_v1"  # Replace with actual villager ID
villager_state = Everstead.Simulation.Kingdom.Villager.Server.get_full_state(villager_id)

IO.puts("Villager: #{villager_state.villager.name}")
IO.puts("State: #{villager_state.villager.state}")
IO.puts("Current job: #{inspect(villager_state.current_job)}")
IO.puts("Work progress: #{villager_state.work_progress}%")

# Check job manager statistics
job_manager_name = Everstead.Simulation.Kingdom.JobManager.Server.get_for_kingdom("p1")
job_stats = GenServer.call(job_manager_name, :get_state)
IO.puts("Total jobs assigned: #{job_stats.stats.total_assigned}")
IO.puts("Total jobs completed: #{job_stats.stats.total_completed}")
IO.puts("Jobs in queue: #{length(job_stats.job_queue)}")
IO.puts("Active jobs: #{map_size(job_stats.active_jobs)}")
```

### Cancel Jobs

```elixir
# Cancel a specific villager's job
Everstead.Simulation.Kingdom.Villager.Server.cancel_job(villager_id)

# Remove a job from the queue
Everstead.Simulation.Kingdom.JobManager.Server.remove_job("gather_wood_1")

# Clear all jobs (use with caution!)
Everstead.Simulation.Kingdom.JobManager.Server.clear_all_jobs()
```

### Job Types and Examples

```elixir
# Available job types: :gather, :build, :move

# GATHER JOBS - Collect resources
wood_gathering = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_forest",
  type: :gather,
  target: %{resource: :wood, amount: 50, location: %{x: 5, y: 5}},
  status: :pending
}

stone_gathering = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_stone_quarry",
  type: :gather,
  target: %{resource: :stone, amount: 30, location: %{x: 10, y: 10}},
  status: :pending
}

food_gathering = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_food_farm",
  type: :gather,
  target: %{resource: :food, amount: 100, location: %{x: 15, y: 15}},
  status: :pending
}

# BUILD JOBS - Construct buildings
house_construction = %Everstead.Entities.World.Kingdom.Job{
  id: "build_house_residential",
  type: :build,
  target: %{building_type: :house, location: %{x: 20, y: 20}},
  status: :pending
}

farm_construction = %Everstead.Entities.World.Kingdom.Job{
  id: "build_farm_agriculture",
  type: :build,
  target: %{building_type: :farm, location: %{x: 25, y: 25}},
  status: :pending
}

# MOVE JOBS - Relocate villagers
villager_relocation = %Everstead.Entities.World.Kingdom.Job{
  id: "move_villager_to_work",
  type: :move,
  target: %{destination: %{x: 30, y: 30}},
  status: :pending
}
```

### Job Priority System

```elixir
# Jobs are processed by priority: critical > high > normal > low

# Critical jobs (emergency situations)
job_manager_name = Everstead.Simulation.Kingdom.JobManager.Server.get_for_kingdom("p1")
emergency_repair = %Everstead.Entities.World.Kingdom.Job{
  id: "emergency_wall_repair",
  type: :build,
  target: %{building_type: :wall, location: %{x: 0, y: 0}},
  status: :pending
}
GenServer.cast(job_manager_name, {:add_job, emergency_repair, :critical})

# High priority jobs (important tasks)
resource_shortage = %Everstead.Entities.World.Kingdom.Job{
  id: "urgent_food_gathering",
  type: :gather,
  target: %{resource: :food, amount: 200, location: %{x: 5, y: 5}},
  status: :pending
}
GenServer.cast(job_manager_name, {:add_job, resource_shortage, :high})

# Normal priority jobs (regular tasks)
routine_gathering = %Everstead.Entities.World.Kingdom.Job{
  id: "routine_wood_gathering",
  type: :gather,
  target: %{resource: :wood, amount: 25, location: %{x: 10, y: 10}},
  status: :pending
}
GenServer.cast(job_manager_name, {:add_job, routine_gathering, :normal})

# Low priority jobs (optional tasks)
optional_construction = %Everstead.Entities.World.Kingdom.Job{
  id: "optional_decoration",
  type: :build,
  target: %{building_type: :decoration, location: %{x: 35, y: 35}},
  status: :pending
}
GenServer.cast(job_manager_name, {:add_job, optional_construction, :low})
```

### Complete Job Assignment Workflow

```elixir
# 1. Start the system
Application.ensure_all_started(:everstead)
{:ok, _pid} = Everstead.Simulation.Player.Supervisor.start_link({"p1", "Alice", "The Kingdom of Eldoria"})

# 2. Check initial villager states
villagers = Everstead.Simulation.Player.Server.get_villagers("p1")
IO.puts("Initial villager states:")
Enum.map(villagers, fn {id, villager} -> 
  IO.puts("#{villager.name}: #{villager.state}")
end)

# 3. Create multiple jobs
jobs = [
  %Everstead.Entities.World.Kingdom.Job{
    id: "gather_wood_1",
    type: :gather,
    target: %{resource: :wood, amount: 30, location: %{x: 5, y: 5}},
    status: :pending
  },
  %Everstead.Entities.World.Kingdom.Job{
    id: "gather_stone_1",
    type: :gather,
    target: %{resource: :stone, amount: 20, location: %{x: 10, y: 10}},
    status: :pending
  },
  %Everstead.Entities.World.Kingdom.Job{
    id: "build_house_1",
    type: :build,
    target: %{building_type: :house, location: %{x: 15, y: 15}},
    status: :pending
  }
]

# 4. Add jobs to the queue
job_manager_name = Everstead.Simulation.Kingdom.JobManager.Server.get_for_kingdom("p1")
Enum.each(jobs, fn job ->
  GenServer.cast(job_manager_name, {:add_job, job, :normal})
end)

# 5. Trigger job assignment
Everstead.Simulation.Kingdom.JobManager.Server.assign_jobs(job_manager_name, villagers)

# 6. Check job assignment results
IO.puts("\nAfter job assignment:")
villagers_after = Everstead.Simulation.Player.Server.get_villagers("p1")
Enum.map(villagers_after, fn {id, villager} -> 
  IO.puts("#{villager.name}: #{villager.state}")
end)

# 7. Monitor job progress
IO.puts("\nJob manager status:")
job_state = GenServer.call(job_manager_name, :get_state)
IO.puts("Jobs in queue: #{length(job_state.job_queue)}")
IO.puts("Active jobs: #{map_size(job_state.active_jobs)}")
IO.puts("Total assigned: #{job_state.stats.total_assigned}")
IO.puts("Total completed: #{job_state.stats.total_completed}")

# 8. Wait for some ticks to see job completion
Process.sleep(5000)

# 9. Check final status
IO.puts("\nAfter 5 seconds:")
villagers_final = Everstead.Simulation.Player.Server.get_villagers("p1")
Enum.map(villagers_final, fn {id, villager} -> 
  IO.puts("#{villager.name}: #{villager.state}")
end)

job_state_final = GenServer.call(job_manager_name, :get_state)
IO.puts("Jobs completed: #{job_state_final.stats.total_completed}")
```

### Monitor Seasonal Effects

```elixir
# Check how seasons affect your kingdom's productivity
world_state = Everstead.Simulation.World.Server.get_state()
current_season = world_state.season.current

IO.puts("=== Current Seasonal Conditions ===")
IO.puts("Season: #{current_season}")
IO.puts("Year: #{world_state.season.year} (#{Everstead.World.year_name(world_state.season.year)})")
IO.puts("Day: #{Everstead.World.day_of_season(world_state.season)}")
IO.puts("Time: #{Everstead.World.clock_time(world_state.season)} (#{Everstead.World.time_of_day(world_state.season)})")
IO.puts("")

IO.puts("=== Productivity Multipliers ===")
IO.puts("Resource gathering: #{Everstead.World.resource_multiplier(current_season)}x")
IO.puts("Farming: #{Everstead.World.farming_multiplier(current_season)}x")
IO.puts("Construction: #{Everstead.World.construction_multiplier(current_season)}x")
IO.puts("Movement: #{Everstead.World.movement_multiplier(current_season)}x")
IO.puts("Food consumption: #{Everstead.World.food_consumption_multiplier(current_season)}x")
IO.puts("")

# Calculate effective gathering rates
base_wood_rate = 5
base_food_rate = 8
wood_mult = Everstead.World.resource_multiplier(current_season)
food_mult = Everstead.World.farming_multiplier(current_season)

IO.puts("=== Effective Gathering Rates ===")
IO.puts("Wood: #{base_wood_rate} * #{wood_mult} = #{floor(base_wood_rate * wood_mult)} per tick")
IO.puts("Food: #{base_food_rate} * #{food_mult} = #{floor(base_food_rate * food_mult)} per tick")
```

### Seasonal Strategy Tips

```elixir
# Plan your kingdom's activities based on the current season
case current_season do
  :spring ->
    IO.puts("🌱 Spring Strategy: Focus on farming and preparation for summer")
    IO.puts("   - Plant crops and gather food (1.3x farming bonus)")
    IO.puts("   - Build infrastructure (1.1x construction bonus)")
    IO.puts("   - Stockpile resources for summer projects")
    
  :summer ->
    IO.puts("☀️ Summer Strategy: Optimal time for major projects")
    IO.puts("   - Gather resources aggressively (1.2x resource bonus)")
    IO.puts("   - Farm intensively (1.5x farming bonus)")
    IO.puts("   - Build major structures (1.2x construction bonus)")
    IO.puts("   - Villagers move faster (1.1x movement bonus)")
    
  :fall ->
    IO.puts("🍂 Fall Strategy: Harvest and prepare for winter")
    IO.puts("   - Continue farming (1.2x farming bonus)")
    IO.puts("   - Gather resources (1.1x resource bonus)")
    IO.puts("   - Villagers move slower (0.9x movement penalty)")
    IO.puts("   - Stockpile food for winter")
    
  :winter ->
    IO.puts("❄️ Winter Strategy: Survive the harsh conditions")
    IO.puts("   - Focus on indoor activities")
    IO.puts("   - Reduced resource gathering (0.7x penalty)")
    IO.puts("   - Poor farming conditions (0.3x penalty)")
    IO.puts("   - Slow construction (0.6x penalty)")
    IO.puts("   - Higher food consumption (1.3x penalty)")
    IO.puts("   - Villagers move slowly (0.7x movement penalty)")
end
```

## Check Villager States

```elixir
# Get villager states from the server processes (these are the active villagers)
villager_states = Everstead.Simulation.Player.Server.get_villagers("p1")
Enum.map(villager_states, fn {_id, villager} -> 
  case villager.state do
    :working -> "#{villager.name} is working"
    :idle -> "#{villager.name} is idle"
    :moving -> "#{villager.name} is moving"
    :resting -> "#{villager.name} is resting"
    _ -> "#{villager.name} is #{villager.state}"
  end
end)
```

## Create Buildings

```elixir
# Create a building using the Kingdom context module
# Note: This requires a player, tile, and location
# For now, we'll just show the structure

# Example of how to create a building (requires proper setup):
# {:ok, {updated_player, building}} = Everstead.Kingdom.place_building(player, tile, :house, {20, 20})
```

## Advanced: Working with Entities

```elixir
# Create entities directly using structs
player_entity = %Everstead.Entities.Player{
  id: "p2",
  name: "Charlie"
}

villager_entity = %Everstead.Entities.World.Kingdom.Villager{
  id: "v2",
  name: "Dave",
  profession: :builder,
  state: :idle
}

resource_entity = %Everstead.Entities.World.Resource{
  type: :wood,
  amount: 100,
  location: %{x: 5, y: 5}
}
```

## Seasonal Effects

The game features a comprehensive seasonal system that affects all major game mechanics:

### Resource Gathering
```elixir
# Check current seasonal multipliers
world_state = Everstead.Simulation.World.Server.get_state()
current_season = world_state.season.current

IO.puts("Current season: #{current_season}")
IO.puts("Resource multiplier: #{Everstead.World.resource_multiplier(current_season)}")
IO.puts("Farming multiplier: #{Everstead.World.farming_multiplier(current_season)}")
IO.puts("Construction multiplier: #{Everstead.World.construction_multiplier(current_season)}")
IO.puts("Movement multiplier: #{Everstead.World.movement_multiplier(current_season)}")
IO.puts("Food consumption multiplier: #{Everstead.World.food_consumption_multiplier(current_season)}")
```

### Seasonal Impact on Gameplay
- **Spring**: Good for farming (1.3x), normal resources (1.0x), slightly faster construction (1.1x)
- **Summer**: Best for everything - resources (1.2x), farming (1.5x), construction (1.2x), faster movement (1.1x)
- **Fall**: Good for farming (1.2x), slightly better resources (1.1x), normal construction (1.0x), slower movement (0.9x)
- **Winter**: Harsh - reduced resources (0.7x), poor farming (0.3x), slow construction (0.6x), slow movement (0.7x)

### Strategic Planning
```elixir
# Plan your kingdom development around seasons
# Summer is optimal for major projects
# Winter requires stockpiling resources and food
# Spring is good for farming and preparation
# Fall is balanced but villagers move slower
```

## What Currently Works

✅ Starting the application and player simulation with custom kingdom names  
✅ Getting player and kingdom state with 5 randomly named medieval villagers  
✅ Default buildings (houses, farms, lumberyard, storage) with construction progress  
✅ Substantial starting resources (500 wood, 300 stone, 1000 food)  
✅ Basic entity creation using structs  
✅ Kingdom resource management functions  
✅ Player and kingdom supervisor management  
✅ Realistic kingdom builder game setup with medieval theming  
✅ **Job assignment system with priority queues**  
✅ **Villager job management (gather, build, move)**  
✅ **Automatic job assignment to idle villagers**  
✅ **Job progress tracking and completion**  
✅ **Job cancellation and queue management**  
✅ **Comprehensive seasonal effects on all game mechanics**  
✅ **Seasonal resource gathering multipliers**  
✅ **Seasonal construction speed modifiers**  
✅ **Seasonal movement speed effects**  
✅ **Seasonal food consumption rates**  
✅ **Immersive seasonal logging and context**  

## Stop Simulation

```elixir
# Stop the player supervisor (this stops all related processes)
Process.exit(Process.whereis(Everstead.Simulation.Player.Supervisor), :normal)
```
