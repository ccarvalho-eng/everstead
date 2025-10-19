# Everstead IEx Tutorial

Welcome to Everstead, a kingdom simulation game built with Elixir and Phoenix! This tutorial will guide you through playing the game using IEx (Interactive Elixir).

## Table of Contents

1. [Getting Started](#getting-started)
2. [Game Overview](#game-overview)
3. [Starting Your Kingdom](#starting-your-kingdom)
4. [Managing Resources](#managing-resources)
5. [Building Structures](#building-structures)
6. [Managing Villagers](#managing-villagers)
7. [Job Management](#job-management)
8. [Seasonal Effects](#seasonal-effects)
9. [Advanced Commands](#advanced-commands)
10. [Troubleshooting](#troubleshooting)

## Getting Started

### Starting the Game

First, start the Phoenix application with IEx:

```bash
iex -S mix phx.server
```

This will start the web server and all game systems. You'll see output indicating that the World Server, Player Supervisor, Villager Supervisor, and Job Manager are all running.

### Verifying the Game is Running

Check that all systems are operational:

```elixir
# Check world state
Everstead.Simulation.World.Server.get_state()

# Check job manager state
Everstead.Simulation.Kingdom.JobManager.Server.get_state()

# Check current season
Everstead.Simulation.World.Server.get_season()
```

## Game Overview

Everstead is a kingdom simulation where you:

- **Manage Resources**: Wood, Stone, and Food
- **Build Structures**: Houses, Farms, Lumberyards, and Storage
- **Assign Villagers**: Create and manage villagers to work on tasks
- **Plan for Seasons**: Each season affects resource gathering and construction
- **Grow Your Kingdom**: Expand and develop your settlement

### Key Game Systems

- **World Server**: Manages time progression and seasons
- **Player Server**: Tracks your kingdom's state and resources
- **Villager Servers**: Individual villagers that can work on jobs
- **Job Manager**: Assigns tasks to idle villagers
- **Kingdom Builder**: Handles construction and building placement

## Starting Your Kingdom

### Creating Your First Player

Start by creating a player (your kingdom):

```elixir
# Start a new player
{:ok, _pid} = Everstead.Simulation.Player.Supervisor.start_player("player1", "My Kingdom")

# Check your player's state
player = Everstead.Simulation.Player.Server.get_state("player1")
IO.inspect(player, label: "Player State")
```

Your player starts with:
- A kingdom with basic resources: `%{wood: 0, stone: 0, food: 0}`
- No villagers or buildings initially
- Ready to begin expansion

### Understanding Your Kingdom Structure

```elixir
# Get your kingdom details
player = Everstead.Simulation.Player.Server.get_state("player1")
kingdom = player.kingdom

IO.inspect(kingdom, label: "Kingdom State")
# %Everstead.Entities.World.Kingdom{
#   id: "kingdom_player1",
#   name: "My Kingdom's Kingdom",
#   villagers: [],
#   buildings: [],
#   resources: %{wood: 0, stone: 0, food: 0}
# }
```

## Managing Resources

### Checking Resources

```elixir
# Get current resources
player = Everstead.Simulation.Player.Server.get_state("player1")
resources = player.kingdom.resources

IO.inspect(resources, label: "Current Resources")
```

### Resource Gathering Process

In Everstead, resources are gathered through villagers working on jobs. Let's set up the proper resource gathering workflow:

```elixir
# First, create a villager to do the gathering
{:ok, _pid} = Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager("villager1", "Bob", "player1")

# Create a gathering job for wood
gather_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_1",
  type: :gather,
  target: %{type: :wood, location: {10, 10}},
  status: :pending
}

# Add the job to the job manager
Everstead.Simulation.Kingdom.JobManager.add_job(gather_job, :high)

# Assign jobs to idle villagers
villagers = %{"villager1" => Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")}
Everstead.Simulation.Kingdom.JobManager.assign_jobs(villagers)

# Check that the villager is now working
villager = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
IO.inspect(villager.state, label: "Villager State")  # Should be :working
```

### Resource Management Functions

```elixir
# Check if you have enough resources for something
costs = %{wood: 50, stone: 20}
has_resources = Everstead.Kingdom.has_resources?(player.kingdom, costs)

# Get specific resource amount
wood_amount = Everstead.Kingdom.get_resource_amount(player.kingdom, :wood)

# Monitor resource gathering progress
# Villagers will gather resources into their inventory over time
# The game automatically processes these every tick (1 second)
```

### Understanding Resource Flow

In Everstead, resources flow through this process:

1. **Villagers gather resources** into their personal inventory
2. **Resources accumulate** in villager inventories over time
3. **Kingdom resources are updated** when villagers complete jobs or return to base
4. **You can spend kingdom resources** on buildings and other projects

```elixir
# Monitor the resource gathering process
# Check villager inventories to see what they've gathered
villager = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
IO.inspect(villager.inventory, label: "Villager Inventory")

# Check kingdom resources (these update as villagers work)
player = Everstead.Simulation.Player.Server.get_state("player1")
IO.inspect(player.kingdom.resources, label: "Kingdom Resources")

# Check gathering rates to understand how fast resources accumulate
wood_rate = Everstead.Simulation.Kingdom.Villager.Server.get_gathering_rate(:wood)
IO.puts("Wood gathering rate: #{wood_rate} per tick")

# The game ticks every second, so you'll see resources accumulate over time
```

## Building Structures

### Available Building Types

- **House**: Costs 50 wood, 20 stone - Provides housing for villagers
- **Farm**: Costs 30 wood, 10 stone - Generates food
- **Lumberyard**: Costs 40 wood, 30 stone - Generates wood
- **Storage**: Costs 60 wood, 40 stone - Increases storage capacity

### Building Costs

```elixir
# Check building costs
Everstead.Kingdom.get_building_cost(:house)
Everstead.Kingdom.get_building_cost(:farm)
Everstead.Kingdom.get_building_cost(:lumberyard)
Everstead.Kingdom.get_building_cost(:storage)
```

### Placing Buildings

First, you need to gather resources through villager work. Let's set up resource gathering and then build:

```elixir
# First, gather some resources through villager work
# Create multiple gathering jobs for different resources
wood_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_1",
  type: :gather,
  target: %{type: :wood, location: {10, 10}},
  status: :pending
}

stone_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_stone_1", 
  type: :gather,
  target: %{type: :stone, location: {15, 15}},
  status: :pending
}

# Add jobs to the queue
Everstead.Simulation.Kingdom.JobManager.add_job(wood_job, :high)
Everstead.Simulation.Kingdom.JobManager.add_job(stone_job, :high)

# Assign jobs to villagers
villagers = %{"villager1" => Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")}
Everstead.Simulation.Kingdom.JobManager.assign_jobs(villagers)

# Wait for villagers to gather resources (check periodically)
# The game ticks every second, so villagers will gather resources over time
# Check villager inventory to see gathered resources
villager = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
IO.inspect(villager.inventory, label: "Villager Inventory")

# Once you have enough resources, create a tile for building
tile = %Everstead.Entities.World.Tile{
  terrain: :grass,
  building_id: nil
}

# Try to place a house (this will fail if you don't have enough resources)
player = Everstead.Simulation.Player.Server.get_state("player1")
result = Everstead.Kingdom.place_building(
  player, 
  tile, 
  :house, 
  {5, 5}
)

case result do
  {:ok, {updated_player, building}} ->
    IO.puts("Building placed successfully!")
    IO.inspect(building, label: "New Building")
    IO.inspect(updated_player.kingdom.resources, label: "Updated Resources")
  
  {:error, :insufficient_resources} ->
    IO.puts("Not enough resources! Gather more through villager work.")
    IO.inspect(player.kingdom.resources, label: "Current Resources")
  
  {:error, reason} ->
    IO.puts("Failed to place building: #{reason}")
end
```

### Construction Progress

```elixir
# Check if construction is complete
building = # ... your building from above
is_complete = Everstead.Kingdom.construction_complete?(building)

# Advance construction (normally done by game ticks)
advanced_building = Everstead.Kingdom.advance_construction(building, 1)
IO.inspect(advanced_building.construction_progress, label: "Construction Progress")
```

## Managing Villagers

### Creating Villagers

```elixir
# Start a villager
{:ok, villager_pid} = Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager("villager1", "Bob", "player1")

# Check villager state
villager = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
IO.inspect(villager, label: "Villager State")
```

### Villager States

Villagers can be in different states:
- **:idle** - Not working, available for jobs
- **:working** - Currently assigned to a job
- **:moving** - Traveling to a location

### Assigning Jobs to Villagers

```elixir
# Create a gathering job
gather_job = %Everstead.Entities.World.Kingdom.Job{
  id: "job1",
  type: :gather,
  target: %{type: :wood, location: {10, 10}},
  status: :pending
}

# Assign the job to a villager
Everstead.Simulation.Kingdom.Villager.Server.assign_job("villager1", gather_job)

# Check villager state after assignment
villager = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
IO.inspect(villager, label: "Villager After Job Assignment")
```

### Job Types

1. **:gather** - Collect resources (wood, stone, food)
2. **:build** - Work on construction projects
3. **:move** - Travel to a specific location

## Job Management

### Using the Job Manager

The Job Manager automatically assigns jobs to idle villagers:

```elixir
# Add a job to the queue
job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_1",
  type: :gather,
  target: %{type: :wood, location: {15, 15}}
}

Everstead.Simulation.Kingdom.JobManager.add_job(job, :high)

# Check job manager state
job_state = Everstead.Simulation.Kingdom.JobManager.get_state()
IO.inspect(job_state, label: "Job Manager State")
```

### Job Priorities

- **:critical** - Building construction, critical resource gathering
- **:high** - Important resource gathering
- **:normal** - Standard tasks
- **:low** - Optional tasks

### Manual Job Assignment

```elixir
# Get all villagers for a player (you'd need to track this)
villagers = %{"villager1" => villager}

# Trigger job assignment
Everstead.Simulation.Kingdom.JobManager.assign_jobs(villagers)
```

## Seasonal Effects

### Understanding Seasons

The game has four seasons, each lasting 60 ticks (60 seconds in real time):

- **Spring**: 10% faster construction, 30% more food production
- **Summer**: 20% faster construction, 50% more food production, 20% more resources
- **Fall**: Normal construction, 20% more food production, 10% more resources
- **Winter**: 40% slower construction, 70% less food production, 30% less resources

### Checking Current Season

```elixir
# Get current season information
season = Everstead.Simulation.World.Server.get_season()
IO.inspect(season, label: "Current Season")

# Get season as string
season_string = Everstead.World.season_to_string(season.current)
IO.puts("Current season: #{season_string}")
```

### Seasonal Multipliers

```elixir
# Check resource gathering multipliers
current_season = :summer
resource_multiplier = Everstead.World.resource_multiplier(current_season)
farming_multiplier = Everstead.World.farming_multiplier(current_season)
construction_multiplier = Everstead.World.construction_multiplier(current_season)

IO.puts("Resource multiplier: #{resource_multiplier}")
IO.puts("Farming multiplier: #{farming_multiplier}")
IO.puts("Construction multiplier: #{construction_multiplier}")
```

## Advanced Commands

### Monitoring Game State

```elixir
# Get comprehensive game state
world_state = Everstead.Simulation.World.Server.get_state()
player_state = Everstead.Simulation.Player.Server.get_state("player1")
job_state = Everstead.Simulation.Kingdom.JobManager.get_state()

IO.inspect(world_state, label: "World State")
IO.inspect(player_state, label: "Player State")
IO.inspect(job_state, label: "Job Manager State")
```

### Monitoring Resource Gathering Progress

Monitor your game progress by checking villager and kingdom states:

```elixir
# Check villager states and inventories
villager1 = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
villager2 = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager2")
IO.inspect(villager1.inventory, label: "Villager1 Inventory")
IO.inspect(villager2.inventory, label: "Villager2 Inventory")

# Check kingdom resources
player = Everstead.Simulation.Player.Server.get_state("player1")
IO.inspect(player.kingdom.resources, label: "Kingdom Resources")

# Check if you have enough resources for something
has_wood = Everstead.Kingdom.has_resources?(player.kingdom, %{wood: 50, stone: 20})
IO.puts("Has enough resources: #{has_wood}")
```

### Resource Gathering Rates

```elixir
# Check villager gathering rates
wood_rate = Everstead.Simulation.Kingdom.Villager.Server.get_gathering_rate(:wood)
stone_rate = Everstead.Simulation.Kingdom.Villager.Server.get_gathering_rate(:stone)
food_rate = Everstead.Simulation.Kingdom.Villager.Server.get_gathering_rate(:food)

IO.puts("Wood gathering rate: #{wood_rate} per tick")
IO.puts("Stone gathering rate: #{stone_rate} per tick")
IO.puts("Food gathering rate: #{food_rate} per tick")
```

### Waiting for Resources to Accumulate

Since the game runs on a 1-second tick cycle, you need to wait for resources to accumulate. Monitor progress by checking villager and kingdom states:

```elixir
# Check current resources
player = Everstead.Simulation.Player.Server.get_state("player1")
wood_amount = Everstead.Kingdom.get_resource_amount(player.kingdom, :wood)
stone_amount = Everstead.Kingdom.get_resource_amount(player.kingdom, :stone)

IO.puts("Current resources - Wood: #{wood_amount}, Stone: #{stone_amount}")

# Check if you have enough for a house
house_cost = Everstead.Kingdom.get_building_cost(:house)
has_enough = Everstead.Kingdom.has_resources?(player.kingdom, house_cost)
IO.puts("Can build house: #{has_enough}")

# Monitor progress by checking periodically
# The game ticks every second, so villagers will gather resources over time
```

### Building Validation

```elixir
# Check if you can build at a location
tile = %Everstead.Entities.World.Tile{terrain: :grass, building_id: nil}
can_build = Everstead.Kingdom.can_build_at?(tile, :house)

case can_build do
  :ok -> IO.puts("Can build here!")
  {:error, reason} -> IO.puts("Cannot build: #{reason}")
end
```

### Canceling Jobs and Construction

```elixir
# Cancel a villager's job
Everstead.Simulation.Kingdom.Villager.Server.cancel_job("villager1")

# Cancel building construction (if you have a building)
# Everstead.Kingdom.cancel_construction(player, building)
```

## Troubleshooting

### Common Issues

1. **"No process found" errors**: Make sure you've started the player and villager processes
2. **"Insufficient resources"**: Check your kingdom's resource levels
3. **"Invalid terrain"**: Some buildings can't be placed on water or mountains
4. **"Tile occupied"**: The location already has a building

### Debugging Commands

```elixir
# Check if processes are running
Process.whereis(Everstead.Simulation.World.Server)
Process.whereis(Everstead.Simulation.Kingdom.JobManager.Server)

# Check registry entries
Registry.select(Everstead.PlayerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
Registry.select(Everstead.KingdomRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])
Registry.select(Everstead.VillagerRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$2"]}])

# Clear all jobs if needed
Everstead.Simulation.Kingdom.JobManager.Server.clear_all_jobs()

# Monitor resource gathering progress by checking states
player = Everstead.Simulation.Player.Server.get_state("player1")
IO.inspect(player.kingdom.resources, label: "Current Resources")
```

### Getting Help

```elixir
# Get help for specific modules
h Everstead.Simulation.Player.Server
h Everstead.Simulation.Kingdom.Villager.Server
h Everstead.Simulation.Kingdom.Builder
h Everstead.Kingdom
h Everstead.World

# Check available functions in key modules
Everstead.Kingdom.__info__(:functions)
Everstead.World.__info__(:functions)
```

## Example Game Session

Here's a complete example of starting a game session with proper resource gathering:

```elixir
# 1. Start the game (already done with iex -S mix phx.server)

# 2. Create a player
{:ok, _} = Everstead.Simulation.Player.Supervisor.start_player("player1", "My Kingdom")

# 3. Create villagers to do the work
{:ok, _} = Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager("villager1", "Bob", "player1")
{:ok, _} = Everstead.Simulation.Kingdom.Villager.Supervisor.start_villager("villager2", "Alice", "player1")

# 4. Check initial state
player = Everstead.Simulation.Player.Server.get_state("player1")
IO.inspect(player.kingdom.resources, label: "Starting Resources")  # All zeros

# 5. Create gathering jobs for different resources
wood_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_wood_1",
  type: :gather,
  target: %{type: :wood, location: {10, 10}}
}

stone_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_stone_1", 
  type: :gather,
  target: %{type: :stone, location: {15, 15}}
}

food_job = %Everstead.Entities.World.Kingdom.Job{
  id: "gather_food_1",
  type: :gather,
  target: %{type: :food, location: {20, 20}}
}

# 6. Add jobs to queue with different priorities
Everstead.Simulation.Kingdom.JobManager.add_job(wood_job, :high)
Everstead.Simulation.Kingdom.JobManager.add_job(stone_job, :high)
Everstead.Simulation.Kingdom.JobManager.add_job(food_job, :normal)

# 7. Assign jobs to villagers
villagers = %{
  "villager1" => Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1"),
  "villager2" => Everstead.Simulation.Kingdom.Villager.Server.get_state("villager2")
}
Everstead.Simulation.Kingdom.JobManager.assign_jobs(villagers)

# 8. Check villagers are now working
villager1 = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager1")
villager2 = Everstead.Simulation.Kingdom.Villager.Server.get_state("villager2")
IO.inspect(villager1.state, label: "Villager1 State")  # Should be :working
IO.inspect(villager2.state, label: "Villager2 State")  # Should be :working

# 9. Monitor resource gathering over time using built-in tools
# The world server ticks every second, so villagers gather resources automatically

# Monitor progress by checking resources
player = Everstead.Simulation.Player.Server.get_state("player1")
wood_amount = Everstead.Kingdom.get_resource_amount(player.kingdom, :wood)
stone_amount = Everstead.Kingdom.get_resource_amount(player.kingdom, :stone)

IO.puts("Current resources - Wood: #{wood_amount}, Stone: #{stone_amount}")

# Check if you have enough for a house
house_cost = Everstead.Kingdom.get_building_cost(:house)
has_enough = Everstead.Kingdom.has_resources?(player.kingdom, house_cost)
IO.puts("Can build house: #{has_enough}")

# 10. Once you have enough resources, try building
# The game will automatically process resource gathering every tick
# Villagers will accumulate resources in their inventories
# The kingdom's resources will be updated as villagers complete their work
```

## Tips for Success

1. **Start with Resource Gathering**: Create villagers and assign gathering jobs before trying to build
2. **Monitor Progress**: Use the monitoring functions to watch resources accumulate over time
3. **Plan for Seasons**: Stock up on food before winter, build during summer
4. **Manage Villagers**: Keep villagers busy with jobs to maximize efficiency
5. **Use Job Priorities**: Assign critical jobs with higher priority
6. **Be Patient**: Resources accumulate every second, so wait for enough before building
7. **Check Villager Inventories**: See what resources your villagers have gathered
8. **Build Strategically**: Place buildings on suitable terrain once you have resources

Happy kingdom building! 🏰