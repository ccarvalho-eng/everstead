defmodule EverStead.Kingdom do
  @moduledoc """
  Context module for kingdom operations including resource management.
  """

  alias EverStead.Entities.World.Kingdom
  alias EverStead.Entities.World.Resource

  @doc """
  Gets the amount of a specific resource type in the kingdom.

  Returns 0 if the resource is not found.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.get_resource_amount(kingdom, :wood)
      100

      iex> kingdom = %Kingdom{resources: []}
      iex> Kingdom.get_resource_amount(kingdom, :wood)
      0
  """
  @spec get_resource_amount(Kingdom.t(), atom()) :: integer()
  def get_resource_amount(kingdom, resource_type) do
    case Enum.find(kingdom.resources, fn r -> r.type == resource_type end) do
      nil -> 0
      resource -> resource.amount
    end
  end

  @doc """
  Checks if the kingdom has enough resources to cover the given costs.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.has_resources?(kingdom, %{wood: 50})
      true

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> Kingdom.has_resources?(kingdom, %{wood: 150})
      false
  """
  @spec has_resources?(Kingdom.t(), map()) :: boolean()
  def has_resources?(kingdom, costs) do
    Enum.all?(costs, fn {resource_type, required_amount} ->
      get_resource_amount(kingdom, resource_type) >= required_amount
    end)
  end

  @doc """
  Deducts resources from the kingdom.

  Returns the updated kingdom with reduced resource amounts.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> updated = Kingdom.deduct_resources(kingdom, %{wood: 50})
      iex> Kingdom.get_resource_amount(updated, :wood)
      50
  """
  @spec deduct_resources(Kingdom.t(), map()) :: Kingdom.t()
  def deduct_resources(kingdom, costs) do
    updated_resources =
      Enum.map(kingdom.resources, fn resource ->
        case Map.get(costs, resource.type) do
          nil -> resource
          amount -> %{resource | amount: resource.amount - amount}
        end
      end)

    %{kingdom | resources: updated_resources}
  end

  @doc """
  Adds resources to the kingdom.

  Returns the updated kingdom with increased resource amounts.
  If a resource type doesn't exist, it will be created.

  ## Examples

      iex> kingdom = %Kingdom{resources: [%Resource{type: :wood, amount: 100}]}
      iex> updated = Kingdom.add_resources(kingdom, %{wood: 50})
      iex> Kingdom.get_resource_amount(updated, :wood)
      150
  """
  @spec add_resources(Kingdom.t(), map()) :: Kingdom.t()
  def add_resources(kingdom, additions) do
    updated_resources =
      Enum.reduce(additions, kingdom.resources, fn {resource_type, amount}, resources ->
        case Enum.find_index(resources, fn r -> r.type == resource_type end) do
          nil ->
            # Resource doesn't exist, add it
            [%Resource{type: resource_type, amount: amount} | resources]

          index ->
            # Resource exists, update it
            List.update_at(resources, index, fn r ->
              %{r | amount: r.amount + amount}
            end)
        end
      end)

    %{kingdom | resources: updated_resources}
  end
end
