defmodule TwoZeroFourEight.GameServer do
  use GenServer

  defstruct slug: nil, moves: [], registry: nil, status: nil, width: 6, height: 6

  alias TwoZeroFourEight.{
    GamesManager,
    GamesRegistry
  }

  alias __MODULE__.{
    Cell,
    CellsRegistry
  }

  @valid_directions [:up, :down, :left, :right]

  def move(slug, direction) when direction in @valid_directions do
    case server_pid(slug) do
      {:ok, pid} -> GenServer.call(pid, {:move, direction})
      error -> error
    end
  end

  def move(_, _) do
    {:error, :invalid_args}
  end

  def game_state(slug) do
    case server_pid(slug) do
      {:ok, pid} -> GenServer.call(pid, :game_state)
      error -> error
    end
  end

  def server_pid(slug) do
    case GamesRegistry.get(slug) do
      [] -> {:error, :not_found}
      [{pid, _}] -> {:ok, pid}
    end
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

    case length(result) == state.width * state.height and
           Enum.all?(result, fn {_, res} -> res == {:ok, {:ok, :configured}} end) do
      true ->
        spawn_value(state)
        {:noreply, %{state | status: :ready}}

      false ->
        {:stop, :error_creating_cells}
    end
  end

  def handle_call({:move, direction}, _, %{status: st} = state) when st != :won do
    current_state = cells_state(state)

    direction
    |> cells_for_direction(state)
    |> Enum.map(fn pid -> Task.async(fn -> Cell.move(pid, direction) end) end)
    |> Task.yield_many()

    tentative_state = cells_state(state)

    cond do
      current_state == tentative_state ->
        {:reply, {:ok, current_state}, state}

      game_won?(tentative_state) ->
        GamesManager.broadcast_win(state.slug, tentative_state)
        {:reply, {:ok, tentative_state}, %{state | status: :won}}

      true ->
        spawn_value(state)
        new_game_state = cells_state(state)
        GamesManager.broadcast_move(state.slug, new_game_state)
        {:reply, {:ok, new_game_state}, state}
    end
  end

  def handle_call({:move, _}, _, state) do
    {:reply, cells_state(state), state}
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
      Enum.map(1..state.height, fn row ->
        Cell.start_link(slug: state.slug, coordinates: {col, row})
      end)
    end)
    |> Keyword.get_values(:ok)
  end

  defp cells_state(state) do
    state
    |> get_cells()
    |> get_cells_state()
  end

  defp get_cells(%{slug: slug}) do
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
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp serialize_coordinates({col, row}) do
    "#{col}-#{row}"
  end

  defp empty_cells(state) do
    state
    |> get_cells()
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

  defp cells_for_direction(direction, state) do
    cells =
      case direction do
        :down -> CellsRegistry.all_for_row(1, state.slug)
        :up -> CellsRegistry.all_for_row(state.height, state.slug)
        :left -> CellsRegistry.all_for_column(state.width, state.slug)
        :right -> CellsRegistry.all_for_column(1, state.slug)
      end

    Enum.map(cells, &elem(&1, 0))
  end

  defp game_won?(tentative_win_state) do
    values = Map.values(tentative_win_state)
    require Logger
    Logger.warn("Values: #{inspect(values)}")
    2048 in values
  end
end
