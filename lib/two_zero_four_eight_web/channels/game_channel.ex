defmodule TwoZeroFourEightWeb.GameChannel do
  use TwoZeroFourEightWeb, :channel

  alias TwoZeroFourEight.{
    GamesManager,
    GameServer
  }

  def join("games:" <> slug, _, socket) do
    case GamesManager.has_game?(slug) do
      true -> {:ok, socket}
      false -> {:error, :not_found}
    end
  end

  @valid_directions ["up", "down", "left", "right"]
  def handle_in("move", %{"direction" => direction}, socket)
      when direction in @valid_directions do
    slug =
      socket.topic
      |> String.split(":")
      |> Enum.reverse()
      |> List.first()

    GameServer.move(slug, String.to_atom(direction))

    {:noreply, socket}
  end

  def handle_in(_, _, socket) do
    {:noreply, socket}
  end
end
