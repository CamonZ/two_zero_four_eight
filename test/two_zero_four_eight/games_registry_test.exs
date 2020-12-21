defmodule TwoZeroFourEight.GamesRegistryTest do
  use ExUnit.Case

  alias TwoZeroFourEight.{
    GamesRegistry,
    SlugGenerator
  }

  test "name/0 returns the registry's name" do
    assert GamesRegistry.name() == :games_registry
  end

  test "start_link/0 starts the registry", ctx do
    assert {:ok, _} = GamesRegistry.start_link(ctx.test)
  end

  test "register/1 registers the current process with the given slug", ctx do
    {:ok, _} = GamesRegistry.start_link(ctx.test)

    GamesRegistry.register("foo-bar-baz", ctx.test)

    registrations = GamesRegistry.all(ctx.test)
    pid = assert [{"foo-bar-baz", self()}] == registrations
  end

  test "unregister/1 unregisters the current process with the given slug", ctx do
    {:ok, _} = GamesRegistry.start_link(ctx.test)
    GamesRegistry.register("foo-bar-baz", ctx.test)
    registrations = GamesRegistry.all(ctx.test)

    assert [{"foo-bar-baz", self()}] == registrations

    GamesRegistry.unregister("foo-bar-baz", ctx.test)
    registrations = GamesRegistry.all(ctx.test)
    assert registrations == []
  end

  test "get/1 returns a list of tuples with the pids and values under a given slug", ctx do
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
