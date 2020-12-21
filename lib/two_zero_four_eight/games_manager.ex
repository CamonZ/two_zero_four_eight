defmodule TwoZeroFourEight.GamesManager do
  use GenServer

  alias TwoZeroFourEight.{
    SlugGenerator,
    GamesRegistry,
    GameServer
  }

  defstruct supervisor_pid: nil

  def create do
    GenServer.call(__MODULE__, :create_game)
  end

  def get(slug) do
    case GamesRegistry.get(slug) do
      [] ->
        {:error, :not_found}

      [{pid, _}] ->
        {:ok, GameServer.game_state(pid)}
    end
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    case DynamicSupervisor.start_link(strategy: :one_for_one) do
      {:ok, pid} ->
        state = %__MODULE__{supervisor_pid: pid}
        {:ok, state}

      _ ->
        {:error, :unexpected_erro}
    end
  end

  def handle_call(:create_game, _, state) do
    slug = SlugGenerator.create()

    case DynamicSupervisor.start_child(state.supervisor_pid, game_server_spec(slug)) do
      {:ok, _} ->
        {:reply, {:ok, slug}, state}

      _ ->
        {:reply, {:error, :unexpected_error}, state}
    end
  end

  defp game_server_spec(slug) do
    Supervisor.child_spec({GameServer, [slug: slug]}, restart: :permanent)
  end
end
