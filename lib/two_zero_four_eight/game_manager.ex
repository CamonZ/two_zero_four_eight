defmodule TwoZeroFourEight.GameManager do
  alias TwoZeroFourEight.SlugGenerator

  def create do
    slug = SlugGenerator.create()
    {:ok, slug}
  end

  def get(slug) do
  end
end
