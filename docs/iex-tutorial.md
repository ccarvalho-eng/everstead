# IEx Tutorial

## Start the Game

```bash
iex -S mix
```

## Create a Player

```elixir
player = Everstead.Player.create("Alice")
```

## Create a Kingdom

```elixir
kingdom = Everstead.Kingdom.create("My Kingdom")
player = Everstead.Player.add_kingdom(player, kingdom)
```

## Add a Villager

```elixir
villager = Everstead.Villager.create("Bob", :builder)
kingdom = Everstead.Kingdom.add_villager(kingdom, villager)
```

## Create a Job

```elixir
job = Everstead.Job.create(:gather, %{resource: :wood, amount: 10})
kingdom = Everstead.Kingdom.add_job(kingdom, job)
```

## Start Simulation

```elixir
Everstead.Simulation.Player.Server.start_link(player)
```

## Check State

```elixir
Everstead.Simulation.Player.Server.get_state(player.id)
```

## Stop Simulation

```elixir
Everstead.Simulation.Player.Server.stop(player.id)
```
