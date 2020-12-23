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

  describe "handle_call :move" do
    test "returns the received values when it's the last cell and the cell has a value", ctx do
      {:ok, pid} = Cell.start_link(slug: ctx.slug, coordinates: {1, 1})
      :ok = Cell.spawn_value(pid, 8)

      values = [4, 2, 1]

      assert Cell.move(pid, :right, values) == [4, 2, 1]
    end

    test "returns the received values minus the first when it's the last cell and the cell is empty",
         ctx do
      {:ok, pid} = Cell.start_link(slug: ctx.slug, coordinates: {1, 1})

      values = [4, 2, 1]

      assert Cell.move(pid, :right, values) == [2, 1]

      assert Cell.get_value(pid) == 4
    end

    test "returns the received values minus the first when it's the last cell and the cell has an addable value",
         ctx do
      {:ok, pid} = Cell.start_link(slug: ctx.slug, coordinates: {1, 1})
      :ok = Cell.spawn_value(pid, 4)
      values = [4, 2, 1]

      assert Cell.move(pid, :right, values) == [2, 1]

      assert Cell.get_value(pid) == 8
    end

    test "adds the first 2 received values if the values are addable and the cell is empty",
         ctx do
      {:ok, pid} = Cell.start_link(slug: ctx.slug, coordinates: {1, 1})
      values = [4, 4, 2, 1]

      assert Cell.move(pid, :right, values) == [2, 1]

      assert Cell.get_value(pid) == 8
    end

    test "correctly processes a line of values", ctx do
      {:ok, one} = Cell.start_link(slug: ctx.slug, coordinates: {1, 1})
      {:ok, two} = Cell.start_link(slug: ctx.slug, coordinates: {2, 1})
      {:ok, three} = Cell.start_link(slug: ctx.slug, coordinates: {3, 1})
      {:ok, four} = Cell.start_link(slug: ctx.slug, coordinates: {4, 1})
      {:ok, five} = Cell.start_link(slug: ctx.slug, coordinates: {5, 1})
      {:ok, six} = Cell.start_link(slug: ctx.slug, coordinates: {6, 1})
      cells = [one, two, three, four, five, six]

      Enum.each(cells, fn pid -> Task.start(fn -> Cell.find_siblings(pid) end) end)

      Cell.spawn_value(one, 1)
      Cell.spawn_value(two, 1)
      Cell.spawn_value(four, 2)
      Cell.spawn_value(five, 2)
      Cell.spawn_value(six, 2)

      Cell.move(one, :right)

      assert is_nil(Cell.get_value(one))
      assert is_nil(Cell.get_value(two))
      assert is_nil(Cell.get_value(three))

      assert Cell.get_value(four) == 2
      assert Cell.get_value(five) == 2
      assert Cell.get_value(six) == 4
    end
  end

  defp register_sibling(coordinates, ctx) do
    Agent.start_link(fn ->
      CellsRegistry.register(coordinates, ctx.slug)
      %{}
    end)
  end
end
