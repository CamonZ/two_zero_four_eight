defmodule TwoZeroFourEight.SlugGenerator do
  alias __MODULE__.{
    Adjectives,
    Nouns
  }

  @size 10_000

  def create do
    parts = [
      Adjectives.random(),
      Nouns.random(),
      :random.uniform(@size)
    ]

    Enum.join(parts, "-")
  end

  def is_slug?(slug) do
    with [_adj, _noun, number] <- String.split(slug, "-"),
         {val, ""} when is_integer(val) <- Integer.parse(number) do
      true
    else
      _ ->
        false
    end
  end
end
