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

## Create Resources

```elixir
# Add wood resource to kingdom
wood = Everstead.Resource.create(:wood, 50, %{x: 10, y: 10})
kingdom = Everstead.Kingdom.add_resource(kingdom, wood)

# Add stone resource
stone = Everstead.Resource.create(:stone, 30, %{x: 15, y: 15})
kingdom = Everstead.Kingdom.add_resource(kingdom, stone)

# Add food resource
food = Everstead.Resource.create(:food, 20, %{x: 5, y: 5})
kingdom = Everstead.Kingdom.add_resource(kingdom, food)
```

## Create Gathering Jobs

```elixir
# Gather wood
wood_job = Everstead.Job.create(:gather, %{resource: :wood, amount: 10, location: %{x: 10, y: 10}})
kingdom = Everstead.Kingdom.add_job(kingdom, wood_job)

# Gather stone
stone_job = Everstead.Job.create(:gather, %{resource: :stone, amount: 5, location: %{x: 15, y: 15}})
kingdom = Everstead.Kingdom.add_job(kingdom, stone_job)

# Gather food
food_job = Everstead.Job.create(:gather, %{resource: :food, amount: 8, location: %{x: 5, y: 5}})
kingdom = Everstead.Kingdom.add_job(kingdom, food_job)
```

## Start Simulation

```elixir
Everstead.Simulation.Player.Server.start_link(player)
```

## Check Resources

```elixir
# Check current resources
Everstead.Simulation.Player.Server.get_state(player.id)

# Check specific resource amounts
state = Everstead.Simulation.Player.Server.get_state(player.id)
resources = state.kingdom.resources
Enum.map(resources, fn r -> {r.type, r.amount} end)
```

## Create Building Job

```elixir
# Create a house
house = Everstead.Building.create(:house, %{x: 20, y: 20})
kingdom = Everstead.Kingdom.add_building(kingdom, house)

# Create build job
build_job = Everstead.Job.create(:build, %{building: :house, location: %{x: 20, y: 20}})
kingdom = Everstead.Kingdom.add_job(kingdom, build_job)
```

## Stop Simulation

```elixir
Everstead.Simulation.Player.Server.stop(player.id)
```
