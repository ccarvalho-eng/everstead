Application.ensure_all_started(:everstead)

# Start a player to see the enhanced logging in action
{:ok, _pid} =
  Everstead.Simulation.Player.Supervisor.start_link({"p1", "Alice", "The Kingdom of Eldoria"})

IO.puts("=== Final Enhanced Tick Logging System ===")
IO.puts("Notice the tick progression, year numbers, names, and rich seasonal messages...")
IO.puts("")

# Let it run for a while to see different times and events
Process.sleep(12000)

# Show current world state
world_state = Everstead.Simulation.World.Server.get_state()
IO.puts("")
IO.puts("=== Current World State ===")
IO.puts("Full date: #{Everstead.World.format_date(world_state.season)}")

IO.puts(
  "Year info: Year #{world_state.season.year} (#{Everstead.World.year_name(world_state.season.year)})"
)

IO.puts("Day: #{Everstead.World.day_of_season(world_state.season)}")
IO.puts("Time of day: #{Everstead.World.time_of_day(world_state.season)}")
IO.puts("Ticks elapsed: #{world_state.season.ticks_elapsed}")

IO.puts(
  "Weather: #{Everstead.World.get_weather(world_state.season.current, Everstead.World.time_of_day(world_state.season))}"
)

IO.puts(
  "World event: #{Everstead.World.get_world_event(world_state.season.current, Everstead.World.time_of_day(world_state.season))}"
)

# Show some year names
IO.puts("")
IO.puts("=== Sample Year Names ===")

Enum.each(1..10, fn year ->
  IO.puts("Year #{year}: #{Everstead.World.year_name(year)}")
end)
