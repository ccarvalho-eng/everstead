# API Reference

## Player

```elixir
Everstead.Player.create(name)
Everstead.Player.add_kingdom(player, kingdom)
```

## Kingdom

```elixir
Everstead.Kingdom.create(name)
Everstead.Kingdom.add_villager(kingdom, villager)
Everstead.Kingdom.add_building(kingdom, building)
Everstead.Kingdom.add_job(kingdom, job)
```

## Villager

```elixir
Everstead.Villager.create(name, profession)
Everstead.Villager.update_state(villager, state)
```

## Building

```elixir
Everstead.Building.create(type, location)
Everstead.Building.update_progress(building, progress)
```

## Job

```elixir
Everstead.Job.create(type, target)
Everstead.Job.assign(job, villager_id)
```

## Resource

```elixir
Everstead.Resource.create(type, amount, location)
Everstead.Resource.update_amount(resource, amount)
```

## World

```elixir
Everstead.World.create(width, height)
Everstead.World.get_tile(world, x, y)
Everstead.World.update_season(world, season)
```

## Simulation

```elixir
Everstead.Simulation.Player.Server.start_link(player)
Everstead.Simulation.Player.Server.get_state(player_id)
Everstead.Simulation.Player.Server.stop(player_id)
```
