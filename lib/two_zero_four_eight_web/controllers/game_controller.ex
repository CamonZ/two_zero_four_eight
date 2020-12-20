defmodule TwoZeroFourEightWeb.GameController do
  use TwoZeroFourEightWeb, :controller

  alias TwoZeroFourEight.GameManager

  def index(conn, _) do
    render(conn, "index.html")
  end

  def new(conn, _) do
    redirect(conn, to: Routes.game_path(conn, :create))
  end

  def create(conn, _) do
    case GameManager.create() do
      {:ok, slug} ->
        redirect(conn, to: Routes.game_path(conn, :show, slug))

      _ ->
        conn
        |> put_flash(:error, "There was an error creating the game")
        |> redirect(to: Routes.game_path(conn, :index))
    end
  end

  def show(conn, %{"id" => _slug}) do
    render(conn, "show.html")
  end
end
