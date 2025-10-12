defmodule EverStead.Entities.ResourceTest do
  use ExUnit.Case, async: true

  alias EverStead.Entities.World.Resource

  test "creates a resource with valid attributes" do
    attributes = %{
      type: :wood,
      amount: 100,
      location: {1, 2}
    }

    resource = struct(Resource, attributes)

    assert resource.type == :wood
    assert resource.amount == 100
    assert resource.location == {1, 2}
  end

  test "creates a resource with default values" do
    attributes = %{
      type: :stone
    }

    resource = struct(Resource, attributes)

    assert resource.type == :stone
    assert resource.amount == 0
    assert resource.location == nil
  end
end
