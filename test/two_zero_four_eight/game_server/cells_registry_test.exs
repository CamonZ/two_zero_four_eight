defmodule TwoZeroFourEight.GameServer.CellsRegistryTest do
  use ExUnit.Case

  alias TwoZeroFourEight.SlugGenerator
  alias TwoZeroFourEight.GameServer.CellsRegistry

  setup do
    slug = SlugGenerator.create()
    {:ok, _} = CellsRegistry.start_link(slug)

    %{slug: slug}
  end

  describe "register/2" do
    test "registers the current process under the coordinates, col, row and cells", ctx do
      CellsRegistry.register({1, 5}, ctx.slug)

      assert CellsRegistry.all(ctx.slug) == [{self(), {1, 5}}]
      assert CellsRegistry.all_for_row(5, ctx.slug) == [{self(), 5}]
      assert CellsRegistry.all_for_column(1, ctx.slug) == [{self(), 1}]
    end
  end

  test "unregister/1 unregisters the current process with the given slug", ctx do
    CellsRegistry.register({6, 1}, ctx.slug)
    CellsRegistry.unregister({6, 1}, ctx.slug)

    assert CellsRegistry.all_for_row(1, ctx.slug) == []
    assert CellsRegistry.all_for_column(6, ctx.slug) == []
    assert CellsRegistry.all(ctx.slug) == []
  end

  test "get_by_coordinates/2 returns a single item list with the pid at the coordinates", ctx do
    CellsRegistry.register({3, 5}, ctx.slug)
    assert CellsRegistry.get_by_coordinates({3, 5}, ctx.slug) == [{self(), ""}]
  end

  test "all_for_column/2 returns all the pids for the given column", ctx do
    {:ok, pid_one} =
      Agent.start_link(fn ->
        CellsRegistry.register({2, 3}, ctx.slug)
        %{}
      end)

    {:ok, pid_two} =
      Agent.start_link(fn ->
        CellsRegistry.register({2, 4}, ctx.slug)
        %{}
      end)

    {:ok, pid_three} =
      Agent.start_link(fn ->
        CellsRegistry.register({3, 1}, ctx.slug)
        %{}
      end)

    entries = CellsRegistry.all_for_column(2, ctx.slug)

    assert length(entries) == 2
    assert {pid_one, 2} in entries
    assert {pid_two, 2} in entries

    assert CellsRegistry.all_for_column(3, ctx.slug) == [{pid_three, 3}]
  end
end
