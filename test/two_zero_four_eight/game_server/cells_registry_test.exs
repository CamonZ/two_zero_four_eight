defmodule TwoZeroFourEight.GameServer.CellsRegistryTest do
  use ExUnit.Case

  alias TwoZeroFourEight.SlugGenerator
  alias TwoZeroFourEight.GameServer.CellsRegistry

  setup do
    slug = SlugGenerator.create()
    {:ok, _} = GamesRegistry.start_link(slug)

    %{slug: slug}
  end

  describe "register/2" do
    test "registers the current process under the coordinates, col, row and cells", ctx do
      CellsRegistry.register({1, 5}, ctx.slug)
      CellsRegistry.all(ctx.slug) == [{self(), {1, 5}}]

      CellsRegistry.all_for_row(5, ctx.slug) == [{self(), {1, 5}}]
      CellsRegistry.all_for_column(1, ctx.slug) == [{self(), {1, 5}}]
    end
  end

  test "unregister/1 unregisters the current process with the given slug" do
    {:ok, _} = GamesRegistry.start_link(ctx.test)
    GamesRegistry.register("foo-bar-baz", ctx.test)
    registrations = GamesRegistry.all(ctx.test)

    assert [{"foo-bar-baz", self()}] == registrations

    GamesRegistry.unregister("foo-bar-baz", ctx.test)
    registrations = GamesRegistry.all(ctx.test)
    assert registrations == []
  end

  test "get_by_coordinates/2 returns a single item list with the pid at the given coordinates" do
    {:ok, _} = GamesRegistry.start_link(ctx.test)
    GamesRegistry.register("foo-bar-baz", ctx.test)

    result = GamesRegistry.get("foo-bar-baz", ctx.test)

    assert result == [{self(), "foo-bar-baz"}]
  end

  describe "has_slug/1" do
    setup ctx do
      {:ok, _} = GamesRegistry.start_link(ctx.test)
      GamesRegistry.register("foo-bar-baz", ctx.test)

      ctx
    end

    test "returns true when slug is in the registry", ctx do
      assert GamesRegistry.has_slug?("foo-bar-baz", ctx.test)
    end

    test "returns false when the slug is not in the registry", ctx do
      refute GamesRegistry.has_slug?("some-other-slug", ctx.test)
    end
  end

  test "all/0 returns all slugs and pids in the registry", ctx do
    slug_one = SlugGenerator.create()
    slug_two = SlugGenerator.create()

    {:ok, _} = GamesRegistry.start_link(ctx.test)

    {:ok, pid_one} =
      Agent.start(fn ->
        GamesRegistry.register(slug_one, ctx.test)

        %{}
      end)

    {:ok, pid_two} =
      Agent.start(fn ->
        GamesRegistry.register(slug_two, ctx.test)
        %{}
      end)

    registrations = GamesRegistry.all(ctx.test)

    assert length(registrations) == 2
    assert {slug_one, pid_one} in registrations
    assert {slug_two, pid_two} in registrations
  end
end
