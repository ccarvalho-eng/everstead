defmodule EverStead.Entities.Resource do
  @moduledoc """
  Represents a resource in the game world.
  """
  use TypedStruct

  @type type :: :wood | :stone | :food

  typedstruct do
    field :type, type()
    field :amount, integer(), default: 0
    field :location, {integer(), integer()} | nil, default: nil
  end
end
