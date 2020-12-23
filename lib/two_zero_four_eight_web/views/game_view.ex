defmodule TwoZeroFourEightWeb.GameView do
  use TwoZeroFourEightWeb, :view

  def organized_state(state) do
    state
    |> Enum.sort()
    |> Enum.chunk_every(6)
  end

  def class_for_tile(coord, value) do
    "tile tile-#{value} tile-position-#{coord}"
  end

  def class_for_win(state) do
    case 2048 in Map.values(state) do
      true -> ""
      false -> "not-visible"
    end
  end
end
