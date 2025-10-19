# Everstead Game Mechanics Guide

This document provides a detailed explanation of all game mechanics in Everstead, a kingdom simulation game built with Elixir and Phoenix.

## Table of Contents

1. [Core Systems](#core-systems)
2. [Resource Management](#resource-management)
3. [Building System](#building-system)
4. [Villager System](#villager-system)
5. [Job System](#job-system)
6. [Seasonal System](#seasonal-system)
7. [World Simulation](#world-simulation)
8. [Process Architecture](#process-architecture)

## Core Systems

### World Server

The World Server is the central coordinator of the game simulation:

- **Tick Rate**: 1 second (1000ms)
- **Responsibilities**:
  - Manages time progression
  - Tracks seasons and years
  - Broadcasts tick events to all game entities
  - Logs season changes and game state

```elixir
# World Server manages these core functions:
- Everstead.Simulation.World.Server.get_season()
- Everstead.Simulation.World.Server.get_state()
```

### Player System

Each player has their own kingdom with:

- **Unique ID**: String identifier for the player
- **Kingdom**: Contains resources, villagers, and buildings
- **Resources**: Wood, Stone, and Food
- **Villagers**: Workers that can be assigned jobs
- **Buildings**: Structures that provide various benefits

## Resource Management

### Resource Types

1. **Wood** - Primary building material
   - Base gathering rate: 5 per tick
   - Used for: Houses, Farms, Lumberyards, Storage

2. **Stone** - Secondary building material
   - Base gathering rate: 3 per tick
   - Used for: Houses, Farms, Lumberyards, Storage

3. **Food** - Sustenance for villagers
   - Base gathering rate: 8 per tick
   - Used for: Villager maintenance (future feature)

### Resource Operations

```elixir
# Check resource amount
Everstead.Kingdom.get_resource_amount(kingdom, :wood)

# Check if you have enough resources
Everstead.Kingdom.has_resources?(kingdom, %{wood: 50, stone: 20})

# Add resources
Everstead.Kingdom.add_resources(kingdom, %{wood: 100})

# Deduct resources
EverStead.Kingdom.deduct_resources(kingdom, %{wood: 50})
```

### Resource Storage

Resources are stored in the kingdom's resource map:

```elixir
%{
  wood: 100,
  stone: 50,
  food: 30
}
```

## Building System

### Building Types

| Building | Wood Cost | Stone Cost | Food Cost | Construction Rate | Purpose |
|----------|-----------|------------|-----------|-------------------|---------|
| House | 50 | 20 | 0 | 10/tick | Villager housing |
| Farm | 30 | 10 | 0 | 8/tick | Food production |
| Lumberyard | 40 | 30 | 0 | 12/tick | Wood production |
| Storage | 60 | 40 | 0 | 15/tick | Resource storage |

### Building Placement

Buildings can only be placed on suitable terrain:

- **Valid Terrain**: Grass, Plains
- **Invalid Terrain**: Water, Mountains

### Construction Process

1. **Validation**: Check terrain, resources, and tile availability
2. **Resource Deduction**: Remove required resources from kingdom
3. **Building Creation**: Create building with 0% construction progress
4. **Construction**: Villagers work to complete the building
5. **Completion**: Building becomes functional at 100% progress

### Construction Mechanics

```elixir
# Place a building
EverStead.Simulation.Kingdom.Builder.place_building(player, tile, :house, {x, y})

# Advance construction
EverStead.Simulation.Kingdom.Builder.advance_construction(building, ticks)

# Check if complete
EverStead.Simulation.Kingdom.Builder.construction_complete?(building)

# Cancel construction (50% refund if <50% complete)
EverStead.Simulation.Kingdom.Builder.cancel_construction(player, building)
```

### Seasonal Construction Effects

Construction speed is affected by seasons:

- **Spring**: 10% faster (1.1x multiplier)
- **Summer**: 20% faster (1.2x multiplier)
- **Fall**: Normal speed (1.0x multiplier)
- **Winter**: 40% slower (0.6x multiplier)

## Villager System

### Villager States

1. **:idle** - Available for job assignment
2. **:working** - Currently assigned to a job
3. **:moving** - Traveling to a location

### Villager Properties

- **ID**: Unique identifier
- **Name**: Display name
- **State**: Current activity state
- **Profession**: Specialization (future feature)
- **Location**: Current position (x, y coordinates)
- **Inventory**: Carried resources

### Villager Management

```elixir
# Start a villager
EverStead.Simulation.Kingdom.Villager.Supervisor.start_villager(id, name, player_id)

# Get villager state
EverStead.Simulation.Kingdom.Villager.Server.get_state(villager_id)

# Assign a job
EverStead.Simulation.Kingdom.Villager.Server.assign_job(villager_id, job)

# Cancel current job
EverStead.Simulation.Kingdom.Villager.Server.cancel_job(villager_id)
```

### Villager Movement

Villagers move at 1 tile per tick when traveling:

```elixir
# Movement is handled automatically when assigned a :move job
# Villagers will move towards their target location
```

## Job System

### Job Types

1. **:gather** - Collect resources from the environment
   - Target: Resource type and location
   - Villagers gather resources into their inventory

2. **:build** - Work on construction projects
   - Target: Building being constructed
   - Villagers advance construction progress

3. **:move** - Travel to a specific location
   - Target: Destination coordinates
   - Villagers move towards the target

### Job Priority System

Jobs are assigned based on priority:

1. **:critical** - Building construction, critical resource gathering
2. **:high** - Important resource gathering
3. **:normal** - Standard tasks
4. **:low** - Optional tasks

### Job Management

```elixir
# Add job to queue
EverStead.Simulation.Kingdom.JobManager.add_job(job, priority)

# Remove job from queue
EverStead.Simulation.Kingdom.JobManager.remove_job(job_id)

# Assign jobs to idle villagers
EverStead.Simulation.Kingdom.JobManager.assign_jobs(villagers)

# Complete a job
EverStead.Simulation.Kingdom.JobManager.complete_job(job_id, villager_id)

# Check job manager state
EverStead.Simulation.Kingdom.JobManager.get_state()
```

### Job Assignment Process

1. **Idle Detection**: Find villagers with `:idle` state
2. **Priority Sorting**: Jobs are sorted by priority in the queue
3. **Assignment**: Highest priority job is assigned to first idle villager
4. **Tracking**: Job is moved from queue to active jobs
5. **Completion**: Job is removed when completed

## Seasonal System

### Season Cycle

The game follows a four-season cycle:

1. **Spring** (60 ticks)
2. **Summer** (60 ticks)
3. **Fall** (60 ticks)
4. **Winter** (60 ticks)

After Winter, the cycle returns to Spring and the year increments.

### Seasonal Effects

#### Resource Gathering Multipliers

| Season | Wood/Stone | Food |
|--------|------------|------|
| Spring | 1.0x | 1.3x |
| Summer | 1.2x | 1.5x |
| Fall | 1.1x | 1.2x |
| Winter | 0.7x | 0.3x |

#### Construction Multipliers

| Season | Multiplier |
|--------|------------|
| Spring | 1.1x |
| Summer | 1.2x |
| Fall | 1.0x |
| Winter | 0.6x |

### Seasonal Functions

```elixir
# Get current season
EverStead.Simulation.World.Server.get_season()

# Get seasonal multipliers
EverStead.World.resource_multiplier(:summer)  # 1.2
EverStead.World.farming_multiplier(:summer)   # 1.5
EverStead.World.construction_multiplier(:summer)  # 1.2

# Convert season to string
EverStead.World.season_to_string(:spring)  # "Spring"
```

## World Simulation

### Tick System

The world simulation runs on a 1-second tick cycle:

1. **World Tick**: World Server processes the tick
2. **Season Update**: Season progression is calculated
3. **Broadcast**: Tick events are sent to all players and villagers
4. **Processing**: Each entity processes the tick event
5. **Scheduling**: Next tick is scheduled

### Time Progression

- **1 Tick** = 1 second real time
- **1 Season** = 60 ticks (1 minute)
- **1 Year** = 240 ticks (4 minutes)

### Simulation Flow

```
World Server Tick
    ↓
Update Season
    ↓
Broadcast to Players
    ↓
Broadcast to Villagers
    ↓
Process Player Updates
    ↓
Process Villager Updates
    ↓
Schedule Next Tick
```

## Process Architecture

### Process Hierarchy

```
Everstead.Application
├── Everstead.Simulation.World.Supervisor
│   ├── Everstead.Simulation.World.Server
│   └── Everstead.Simulation.Player.DynamicSupervisor
│       └── Everstead.Simulation.Player.Supervisor (per player)
│           ├── Everstead.Simulation.Player.Server
│           └── Everstead.Simulation.Kingdom.Supervisor
│               ├── Everstead.Simulation.Kingdom.Villager.Supervisor
│               │   └── Everstead.Simulation.Kingdom.Villager.Server (per villager)
│               └── Everstead.Simulation.Kingdom.JobManager.Supervisor
│                   └── Everstead.Simulation.Kingdom.JobManager.Server
└── EversteadWeb.Endpoint
```

### Registry Usage

The game uses three registries for process discovery:

1. **PlayerRegistry**: Maps player IDs to player server PIDs
2. **KingdomRegistry**: Maps kingdom IDs to kingdom supervisor PIDs
3. **VillagerRegistry**: Maps villager IDs to villager server PIDs

### Process Communication

- **GenServer.call/2**: Synchronous communication (getting state)
- **GenServer.cast/2**: Asynchronous communication (assigning jobs)
- **send/2**: Direct message passing (tick events)

### Error Handling

- **Process Crashes**: Supervisors restart crashed processes
- **Stale Jobs**: Job Manager detects and reassigns orphaned jobs
- **Resource Validation**: All operations validate resources before execution

## Advanced Mechanics

### Resource Gathering

Villagers gather resources based on:

1. **Base Rate**: Fixed rate per resource type
2. **Seasonal Multiplier**: Current season affects gathering speed
3. **Villager Efficiency**: Future feature for villager specialization

### Building Benefits

Buildings provide various benefits (future features):

- **Houses**: Increase villager capacity
- **Farms**: Generate food over time
- **Lumberyards**: Generate wood over time
- **Storage**: Increase resource storage capacity

### Kingdom Growth

As your kingdom grows:

1. **More Villagers**: Hire additional workers
2. **More Buildings**: Construct various structures
3. **Resource Efficiency**: Optimize gathering and production
4. **Seasonal Planning**: Prepare for seasonal changes

## Performance Considerations

### Memory Management

- **Streams**: Use LiveView streams for large collections
- **Process Isolation**: Each entity runs in its own process
- **Resource Cleanup**: Processes clean up when no longer needed

### Scalability

- **Horizontal Scaling**: Multiple players can run simultaneously
- **Process Distribution**: Each player's kingdom is isolated
- **Efficient Broadcasting**: Tick events are efficiently distributed

## Future Enhancements

### Planned Features

1. **Villager Specialization**: Different villager types with unique abilities
2. **Building Production**: Buildings that generate resources over time
3. **Trade System**: Exchange resources between players
4. **Combat System**: Defend against threats
5. **Technology Tree**: Research new buildings and abilities
6. **Multiplayer**: Real-time multiplayer gameplay

### Modding Support

The architecture supports future modding:

- **Plugin System**: Add new building types
- **Custom Jobs**: Create new job types
- **Seasonal Events**: Add special seasonal occurrences
- **Resource Types**: Introduce new resource types

This comprehensive guide covers all the core mechanics of Everstead. The game is designed to be extensible and can grow with additional features while maintaining the solid foundation of resource management, building construction, and villager management.