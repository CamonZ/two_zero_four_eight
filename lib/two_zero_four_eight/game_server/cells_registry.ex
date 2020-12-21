defmodule TwoZeroFourEight.GameServer.CellsRegistry do
  @moduledoc "Registry for Cells in a game"

  def start_link(slug) do
    Registry.start_link(keys: :duplicate, name: to_name(slug))
  end

  def register({col, row} = coordinates, slug) do
    Registry.register(to_name(slug), :cells, coordinates)
    Registry.register(to_name(slug), :cols, col)
    Registry.register(to_name(slug), :rows, row)
    Registry.register(to_name(slug), coordinates, "")
  end

  def unregister({col, row} = coordinates, slug) do
    Registry.unregister(to_name(slug), :cells)
    Registry.unregister_match(to_name(slug), :cols, col)
    Registry.unregister_match(to_name(slug), :rows, row)
    Registry.unregister(to_name(slug), coordinates)
  end

  def get_by_coordinates(coordinates, slug) do
    Registry.lookup(to_name(slug), coordinates)
  end

  def all(slug) do
    Registry.lookup(to_name(slug), :cells)
  end

  def all_for_column(col, slug) do
    Registry.match(to_name(slug), :cols, col)
  end

  def all_for_row(row, slug) do
    Registry.match(to_name(slug), :rows, row)
  end

  defp to_name(slug) do
    String.to_atom("#{slug}_cells")
  end
end
