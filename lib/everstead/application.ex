defmodule Everstead.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EversteadWeb.Telemetry,
      Everstead.Repo,
      {DNSCluster, query: Application.get_env(:everstead, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Everstead.PubSub},
      # Domain-specific registries for process discovery
      {Registry, keys: :unique, name: Everstead.PlayerRegistry},
      {Registry, keys: :unique, name: Everstead.KingdomRegistry},
      {Registry, keys: :unique, name: Everstead.VillagerRegistry},
      # Core simulation processes - World supervises everything
      Everstead.Simulation.World.Supervisor,
      # Start to serve requests, typically the last entry
      EversteadWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Everstead.Supervisor, max_restarts: 5, max_seconds: 10]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EversteadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
