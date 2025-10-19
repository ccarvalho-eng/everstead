# Game Mechanics

## Core Systems

### World
- 100x100 tile grid
- 4 seasons (spring, summer, fall, winter)
- 1-second tick rate

### Player Kingdom
- Villagers (idle, working, moving, resting)
- Buildings (house, farm, lumberyard, storage)
- Resources (wood, stone, food)

### Jobs
- **Build**: Construct buildings
- **Gather**: Collect resources
- **Move**: Relocate villagers

## Process Architecture

```
World.Server (tick coordinator)
├── Player.DynamicSupervisor
    └── Player.Supervisor (per player)
        ├── Player.Server
        └── Kingdom.Supervisor
            ├── Villager.Supervisor
            │   └── Villager.Server (per villager)
            └── JobManager.Supervisor
                └── JobManager.Server
```

## Communication Flow

1. World.Server sends tick to all players
2. Player.Server assigns jobs to JobManager
3. JobManager assigns jobs to idle villagers
4. Villagers execute jobs and update resources
5. State persists in GenServer memory
