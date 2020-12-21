defmodule TwoZeroFourEight.GamesManagerTest do
  use ExUnit.Case

  alias TwoZeroFourEight.{
    GamesManager,
    SlugGenerator
  }

  test "create returns an :ok tuple with an unique slug name" do
    assert {:ok, slug} = GamesManager.create()
    assert SlugGenerator.is_slug?(slug)
  end
end
