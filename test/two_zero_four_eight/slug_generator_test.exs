defmodule TwoZeroFourEight.SlugGeneratorTest do
  use ExUnit.Case

  alias TwoZeroFourEight.SlugGenerator

  test "create returns a unique binary" do
    slug_one = SlugGenerator.create()
    slug_two = SlugGenerator.create()

    parts = String.split(slug_one, "-")
    assert length(parts) == 3

    assert slug_one != slug_two
  end

  describe "is_slug?/1" do
    test "returns true when it's a valid slug" do
      assert SlugGenerator.is_slug?(SlugGenerator.create())
    end

    test "returns false when it's not a valid slug" do
      refute SlugGenerator.is_slug?("clearly-not-a-slug")
      refute SlugGenerator.is_slug?("not_a_slug-1000")
      refute SlugGenerator.is_slug?("one-two-three")
    end
  end
end
