defmodule TwoZeroFourEight.GameServerTest do
  use ExUnit.Case

  alias TwoZeroFourEight.{
    GamesRegistry,
    SlugGenerator,
    GameServer
  }

  alias GameServer.CellsRegistry

  describe "start_link/1" do
    test "can return an :ok tuple with a pid when called with valid args" do
      assert {:ok, pid} = GameServer.start_link(slug: SlugGenerator.create())

      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "returns an error tuple if called with invalid args" do
      assert {:error, :invalid_args} = GameServer.start_link(foo: SlugGenerator.create())
      assert {:error, :invalid_args} = GameServer.start_link("foo")
    end
  end

  describe "init/1" do
    test "registers itself, inits the cells registry and continues to init the cells" do
      slug = SlugGenerator.create()

      assert {:ok, state, continuation} = GameServer.init([slug])

      assert %GameServer{slug: ^slug, registry: pid, status: st} = state

      assert is_pid(pid)
      assert Process.alive?(pid)
      assert st == :starting

      assert continuation == {:continue, :init_cells}
    end

    test "returns an error tuple if called with an existing slug" do
      slug = SlugGenerator.create()
      GamesRegistry.register(slug)

      assert {:error, :slug_collision} = GameServer.init([slug])
    end
  end

  describe "handle_continue/2" do
    test ":init_cells starts the cell servers and organizes them" do
      slug = SlugGenerator.create()
      {:ok, pid} = CellsRegistry.start_link(slug)

      state = %GameServer{
        slug: slug,
        registry: pid
      }

      assert {:noreply, state} = GameServer.handle_continue(:init_cells, state)

      assert state.status == :ready

      cells = CellsRegistry.all(slug)

      assert length(cells) == 36

      for col <- 1..6 do
        for row <- 1..6 do
          assert length(CellsRegistry.all_for_row(row, slug)) == 6
        end

        assert length(CellsRegistry.all_for_column(col, slug)) == 6
      end
    end
  end
end
