defmodule Everstead.MixProject do
  use Mix.Project

  def project do
    [
      app: :everstead,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Everstead.Application, []},
      extra_applications: [:logger, :runtime_tools, :observer, :wx]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  defp docs do
    [
      main: "readme",
      name: "Everstead",
      source_url: "https://github.com/your-username/everstead",
      homepage_url: "https://github.com/your-username/everstead",
      extras: [
        "README.md",
        "docs/iex-tutorial.md",
        "docs/game-mechanics.md"
      ],
      groups_for_modules: [
        "Game Simulation": [
          EverStead.Simulation.World.Server,
          EverStead.Simulation.Player.Server,
          EverStead.Simulation.Kingdom.Villager.Server,
          EverStead.Simulation.Kingdom.JobManager
        ],
        "Utility Modules": [
          EverStead.GameMonitor,
          EverStead.ResourceWaiter
        ],
        "Kingdom Management": [
          EverStead.Kingdom,
          EverStead.Simulation.Kingdom.Builder
        ],
        "World Context": [
          EverStead.World
        ],
        Entities: [
          EverStead.Entities.World.Kingdom,
          EverStead.Entities.World.Resource,
          EverStead.Entities.World.Kingdom.Villager,
          EverStead.Entities.World.Kingdom.Building,
          EverStead.Entities.World.Kingdom.Job,
          EverStead.Entities.World.Season,
          EverStead.Entities.World.Tile
        ]
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind everstead", "esbuild everstead"],
      "assets.deploy": [
        "tailwind everstead --minify",
        "esbuild everstead --minify",
        "phx.digest"
      ],
      docs: ["docs", "cmd ./scripts/docs.sh"],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
