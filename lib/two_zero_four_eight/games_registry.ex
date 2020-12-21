defmodule TwoZeroFourEight.GamesRegistry do
  @moduledoc "Games Registry"

  @registry :games_registry

  def name, do: @registry

  def start_link(name \\ @registry) do
    Registry.start_link(keys: :unique, name: name)
  end

  def register(slug, registry \\ @registry) when is_binary(slug) do
    Registry.register(registry, slug, slug)
  end

  def unregister(slug, registry \\ @registry) when is_binary(slug) do
    Registry.unregister(registry, slug)
  end

  def get(slug, registry \\ @registry) do
    Registry.lookup(registry, slug)
  end

  def has_slug?(slug, registry \\ @registry) do
    case get(slug, registry) do
      [] -> false
      [_ | _] -> true
    end
  end

  def all(registry \\ @registry) do
    Registry.select(registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end
end
