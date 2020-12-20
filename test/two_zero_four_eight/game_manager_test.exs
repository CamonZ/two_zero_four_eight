defmodule TwoZeroFourEight.GameManagerTest do
  use ExUnit.Case

  alias TwoZeroFourEight.{
    GameManager,
    SlugGenerator
  }

  test "create returns an :ok tuple with an unique slug name" do
    assert {:ok, slug} = GameManager.create()
    assert SlugGenerator.is_slug?(slug)
  end
end
