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

  require Logger

  def find_siblings(pid) do
    GenServer.call(pid, :find_siblings)
  end

  def is_empty?(pid) do
    GenServer.call(pid, :is_empty?)
  end

  def get_value(pid) do
    GenServer.call(pid, :get_value)
  end

  @default_value 1
  def spawn_value(pid, value \\ @default_value) do
    GenServer.call(pid, {:spawn_value, value})
  end

  def move(pid, direction, values \\ [])

  def move(pid, direction, values) when not is_nil(pid) do
    GenServer.call(pid, {:move, direction, values})
  end

  def move(nil, _, values) do
    values
  end

  def start_link(opts) when is_list(opts) do
    with {:ok, _} <- Keyword.fetch(opts, :slug),
         {:ok, _} <- Keyword.fetch(opts, :coordinates) do
      GenServer.start_link(__MODULE__, Keyword.take(opts, [:slug, :coordinates]))
    else
      _ ->
        {:error, :invalid_args}
    end
  end

  def start_link(_) do
    {:error, :invalid_args}
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

  def handle_call(:is_empty?, _, state) do
    {:reply, is_nil(state.value), state}
  end

  def handle_call({:spawn_value, value}, _, state) do
    {:reply, :ok, %{state | value: value}}
  end

  def handle_call({:move, direction, received_values}, _, state) do
    {addables, rest} =
      state.siblings
      |> Map.get(direction)
      |> move(direction, pushable_values(received_values, state))
      |> Enum.split(2)

    {new_value, remainder} = process_addables(addables)

    {:reply, List.flatten([remainder | rest]), %{state | value: new_value}}
  end

  def handle_call(:get_value, _, state) do
    {:reply, Map.get(state, :value), state}
  end

  def handle_call(msg, _, state) do
    {:reply, msg, state}
  end

  defp sibling_coordinates({col, row}) do
    %{
      left: {col - 1, row},
      right: {col + 1, row},
      up: {col, row - 1},
      down: {col, row + 1}
    }
  end

  def pushable_values(values, state) do
    case is_nil(state.value) do
      true -> values
      false -> [state.value | values]
    end
  end

  def process_addables([first, second]) when first == second do
    {first + second, []}
  end

  def process_addables([first, second]) when first != second do
    {first, [second]}
  end

  def process_addables(addables) do
    {List.first(addables), []}
  end
end
