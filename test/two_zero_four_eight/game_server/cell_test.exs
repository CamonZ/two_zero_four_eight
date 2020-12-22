defmodule TwoZeroFourEight.GameServer.CellTest do
  use ExUnit.Case

  alias TwoZeroFourEight.SlugGenerator

  alias TwoZeroFourEight.GameServer.{
    Cell,
    CellsRegistry
  }

  setup do
    slug = SlugGenerator.create()
    CellsRegistry.start_link(slug)

    %{slug: slug}
  end

  describe "start_link/1" do
    test "returns an :ok tuple when called with the right args", ctx do
      opts = [
        slug: ctx.slug,
        coordinates: {1, 1}
      ]

      assert {:ok, pid} = Cell.start_link(opts)

      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "returns an :error tuple when called with invalid args" do
      assert {:error, :invalid_args} = Cell.start_link("")
      assert {:error, :invalid_args} = Cell.start_link([])
    end
  end

  describe "init/1" do
    test "registers the cell and returns the server's state", ctx do
      opts = [
        slug: ctx.slug,
        coordinates: {1, 5}
      ]

      assert {:ok, state} = Cell.init(opts)

      assert state.slug == ctx.slug
      assert state.coordinates == {1, 5}

      assert CellsRegistry.get_by_coordinates({1, 5}, ctx.slug) == [{self(), ""}]
    end
  end

  describe "handle_call/3" do
    test ":find_siblings configures the siblings of the current cell", ctx do
      {:ok, top} = register_sibling({3, 5}, ctx)
      {:ok, left} = register_sibling({2, 6}, ctx)
      {:ok, right} = register_sibling({4, 6}, ctx)

      state = %Cell{
        coordinates: {3, 6},
        slug: ctx.slug
      }

      assert {:reply, reply, state} = Cell.handle_call(:find_siblings, nil, state)

      assert reply == {:ok, :configured}

      assert state.siblings == %{
               up: top,
               left: left,
               right: right,
               down: nil
             }

      {:ok, topmost} = register_sibling({3, 4}, ctx)
      {:ok, top_left} = register_sibling({2, 5}, ctx)
      {:ok, top_right} = register_sibling({4, 5}, ctx)
      CellsRegistry.register({3, 6}, ctx.slug)

      state = %Cell{
        coordinates: {3, 5},
        slug: ctx.slug
      }

      {:reply, _, state} = Cell.handle_call(:find_siblings, nil, state)

      assert state.siblings == %{
               up: topmost,
               left: top_left,
               right: top_right,
               down: self()
             }
    end
  end

  defp register_sibling(coordinates, ctx) do
    Agent.start_link(fn ->
      CellsRegistry.register(coordinates, ctx.slug)
      %{}
    end)
  end
end
