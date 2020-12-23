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
    case GameServer.game_state(slug) do
      {:error, :not_found} = err -> err
      other -> {:ok, other}
    end
  end

  def broadcast_move(slug, state) do
    payload = Enum.into(state, %{})
    TwoZeroFourEightWeb.Endpoint.broadcast("games:#{slug}", "moved", payload)
  end

  def broadcast_win(slug) do
    TwoZeroFourEightWeb.Endpoint.broadcast("games:#{slug}", "game_won", %{})
  end

  def has_game?(slug) do
    GamesRegistry.has_slug?(slug)
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
