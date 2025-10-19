# Everstead

A kingdom simulation game built with Elixir and Phoenix. Manage resources, build structures, assign villagers, and grow your kingdom through the seasons.

## 🚀 Quick Start

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

* **[IEx Tutorial](docs/iex-tutorial.md)** - Learn to play the game
* **[Game Mechanics](docs/game-mechanics.md)** - Understand how it works
* **[API Reference](docs/api-reference.md)** - Reference for development

### Generate Latest Docs

```bash
# Generate auto-generated API documentation
mix docs

# View documentation
open doc/index.html
```

## 🎮 Game Features

- **Resource Management**: Wood, Stone, and Food
- **Building System**: Houses, Farms, Lumberyards, and Storage
- **Villager Management**: Create and assign workers to tasks
- **Seasonal Effects**: Each season affects resource gathering and construction
- **Real-time Simulation**: Built with Elixir/OTP for concurrent gameplay
- **Utility Modules**: Built-in tools for monitoring and waiting

## 🛠️ Development

The game is built with modern Elixir/OTP patterns:

- **GenServer processes** for each game entity
- **DynamicSupervisor** for managing players and villagers
- **Registry** for process discovery
- **Phoenix LiveView** for the web interface
- **Ecto** for data modeling

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
