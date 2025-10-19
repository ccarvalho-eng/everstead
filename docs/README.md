# Everstead Documentation

Welcome to the Everstead documentation! This directory contains comprehensive guides and references for playing and developing with the Everstead kingdom simulation game.

## 📚 Documentation Overview

### [IEx Tutorial](iex-tutorial.md)
**Start here!** A complete step-by-step guide for playing Everstead using IEx (Interactive Elixir). This tutorial covers:

- Getting started with the game
- Creating your first kingdom
- Managing resources and villagers
- Building structures
- Understanding seasonal effects
- Advanced gameplay strategies

**Perfect for:** New players who want to learn how to play the game.

### [Game Mechanics Guide](game-mechanics.md)
A detailed explanation of all game systems and mechanics. This guide covers:

- Core game systems and architecture
- Resource management and gathering
- Building system and construction
- Villager management and job assignment
- Seasonal effects and time progression
- Process architecture and communication

**Perfect for:** Players who want to understand how the game works under the hood.

### [Architecture Documentation](architecture.md)
Comprehensive technical documentation covering the system architecture. This guide covers:

- Data modeling and entity relationships
- OTP supervision tree structure
- Process communication patterns
- Registry architecture and process discovery
- Error handling and fault tolerance strategies
- Scalability considerations and performance characteristics

**Perfect for:** Developers who want to understand the system architecture and contribute to the codebase.

### [API Reference](api-reference.md)
Complete reference documentation for all public APIs in the game. This reference covers:

- World Server API
- Player System API
- Villager System API
- Job Management API
- Kingdom Management API
- Building System API
- World Context API
- Utility Modules API (GameMonitor, ResourceWaiter)
- Entity schemas and data structures

**Perfect for:** Developers who want to extend the game or build tools around it.

> **Note:** The API reference is now auto-generated using ExDoc. Run `mix docs` to generate the latest documentation.

## 🎮 Quick Start

1. **Start the game:**
   ```bash
   iex -S mix phx.server
   ```

2. **Follow the [IEx Tutorial](iex-tutorial.md)** to learn the basics

3. **Refer to the [Game Mechanics Guide](game-mechanics.md)** for deeper understanding

4. **Use the [API Reference](api-reference.md)** for development
5. **Generate latest docs** with `mix docs` for auto-generated API documentation

## 🏰 About Everstead

Everstead is a kingdom simulation game built with Elixir and Phoenix. In this game, you:

- **Manage Resources**: Wood, Stone, and Food
- **Build Structures**: Houses, Farms, Lumberyards, and Storage
- **Assign Villagers**: Create and manage workers to complete tasks
- **Plan for Seasons**: Each season affects resource gathering and construction
- **Grow Your Kingdom**: Expand and develop your settlement over time
- **Monitor Progress**: Use built-in utility modules to track game state
- **Wait for Resources**: Programmatically wait for resources to accumulate

## 🛠️ Development

The game is built with modern Elixir/OTP patterns:

- **GenServer processes** for each game entity
- **DynamicSupervisor** for managing players and villagers
- **Registry** for process discovery
- **Phoenix LiveView** for the web interface
- **Ecto** for data modeling

### 📚 Documentation Generation

The project uses ExDoc for automatic API documentation generation:

```bash
# Generate documentation
mix docs

# View documentation
open doc/index.html
```

The documentation includes:
- **Auto-generated API docs** from code comments
- **Module organization** by functionality
- **Interactive examples** and usage patterns
- **Type specifications** and function signatures

## 📖 Reading Order

If you're new to Everstead, we recommend reading the documentation in this order:

1. **[IEx Tutorial](iex-tutorial.md)** - Learn to play the game
2. **[Game Mechanics Guide](game-mechanics.md)** - Understand how it works
3. **[Architecture Documentation](architecture.md)** - Understand the technical design
4. **[API Reference](api-reference.md)** - Reference for development

## 🤝 Contributing

Found an issue with the documentation? Want to add a new guide?

1. Check the existing documentation first
2. Follow the same format and style
3. Include code examples where helpful
4. Test your examples in IEx

## 📝 Documentation Standards

When adding to this documentation:

- Use clear, concise language
- Include code examples for all functions
- Provide both success and error cases
- Keep examples practical and runnable
- Update the table of contents when adding new sections

## 🔗 Related Links

- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix/)
- [Elixir Documentation](https://hexdocs.pm/elixir/)
- [OTP Documentation](https://hexdocs.pm/elixir/GenServer.html)

---

Happy kingdom building! 🏰✨