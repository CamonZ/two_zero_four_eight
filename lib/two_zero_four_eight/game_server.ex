defmodule TwoZeroFourEight.GameServer do
  use GenServer

  defstruct slug: nil, moves: [], registry: nil, status: nil, width: 6, length: 6

  alias TwoZeroFourEight.GamesRegistry

  alias __MODULE__.{
    Cell,
    CellsRegistry
  }

  def move(slug, direction) do
    case GamesRegistry.get(slug) do
      [] -> {:error, :not_found}
      [{pid, _}] -> GenServer.call(pid, {:move, direction})
    end
  end

  def game_state(pid) do
    GenServer.call(pid, :game_state)
  end

  def start_link(opts) when is_list(opts) do
    case Keyword.fetch(opts, :slug) do
      {:ok, slug} ->
        GenServer.start_link(__MODULE__, [slug])

      :error ->
        {:error, :invalid_args}
    end
  end

  def start_link(_) do
    {:error, :invalid_args}
  end

  def init([slug]) do
    with {:ok, _} <- GamesRegistry.register(slug),
         {:ok, pid} <- CellsRegistry.start_link(slug) do
      state = %__MODULE__{slug: slug, registry: pid, status: :starting}
      {:ok, state, {:continue, :init_cells}}
    else
      {:error, {:already_registered, _}} ->
        {:error, :slug_collision}

      _ ->
        {:error, :unexpected_error}
    end
  end

  def handle_continue(:init_cells, state) do
    result =
      state
      |> spawn_cells()
      |> configure_cells()

    case length(result) == state.width * state.length and
           Enum.all?(result, fn {_, res} -> res == {:ok, {:ok, :configured}} end) do
      true ->
        spawn_value(state)
        {:noreply, %{state | status: :ready}}

      false ->
        {:stop, :error_creating_cells}
    end
  end

  @valid_directions [:up, :down, :left, :right]

  def handle_call({:move, direction}, _, state) when direction in @valid_directions do
    {:reply, {:ok, cells_state(state)}, state}
  end

  def handle_call(:game_state, _, state) do
    {:reply, cells_state(state), state}
  end

  defp configure_cells(cells) do
    cells
    |> Enum.map(fn pid -> Task.async(fn -> Cell.find_siblings(pid) end) end)
    |> Task.yield_many()
  end

  defp spawn_cells(state) do
    1..state.width
    |> Enum.flat_map(fn col ->
      Enum.map(1..state.length, fn row ->
        Cell.start_link(slug: state.slug, coordinates: {col, row})
      end)
    end)
    |> Keyword.get_values(:ok)
  end

  defp cells_state(state) do
    state
    |> cells()
    |> get_cells_state()
  end

  defp cells(%{slug: slug}) do
    CellsRegistry.all(slug)
  end

  defp get_cells_state(cells) do
    cells
    |> Enum.map(fn {pid, coord} ->
      {
        serialize_coordinates(coord),
        Cell.get_value(pid)
      }
    end)
    |> Enum.into(%{})
  end

  defp serialize_coordinates({col, row}) do
    "#{col}-#{row}"
  end

  defp empty_cells(state) do
    state
    |> cells()
    |> Enum.map(fn {pid, coord} -> {coord, Cell.is_empty?(pid)} end)
    |> Enum.filter(fn {_, val} -> val end)
  end

  defp spawn_value(state) do
    state
    |> empty_cells()
    |> Enum.random()
    |> elem(0)
    |> CellsRegistry.get_by_coordinates(state.slug)
    |> List.first()
    |> elem(0)
    |> Cell.spawn_value()
  end
end
