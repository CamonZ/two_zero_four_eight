defmodule TwoZeroFourEight.GameServer.Cell do
  use GenServer

  defstruct value: nil,
            coordinates: nil,
            slug: nil,
            siblings: %{
              up: nil,
              down: nil,
              left: nil,
              right: nil
            }

  alias TwoZeroFourEight.GameServer.CellsRegistry

  def find_siblings(pid) do
    GenServer.call(pid, :find_siblings)
  end

  def start_link(opts) do
    with {:ok, _} <- Keyword.fetch(opts, :slug),
         {:ok, _} <- Keyword.fetch(opts, :coordinates) do
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:slug, :coordinates]))
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  def init(slug: slug, coordinates: coordinates) do
    CellsRegistry.register(coordinates, slug)

    state = %__MODULE__{
      slug: slug,
      coordinates: coordinates
    }

    {:ok, state}
  end

  def handle_call(:find_siblings, _, state) do
    siblings =
      state.coordinates
      |> sibling_coordinates()
      |> Enum.map(fn {side, coordinates} ->
        case CellsRegistry.get_by_coordinates(coordinates, state.slug) do
          [] -> {side, nil}
          [{pid, _}] -> {side, pid}
        end
      end)
      |> Enum.into(%{})

    {:reply, {:ok, :configured}, %{state | siblings: siblings}}
  end

  defp sibling_coordinates({col, row}) do
    %{
      left: {col - 1, row},
      right: {col + 1, row},
      up: {col, row - 1},
      down: {col, row + 1}
    }
  end
end
