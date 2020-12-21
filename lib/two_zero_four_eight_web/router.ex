defmodule TwoZeroFourEightWeb.Router do
  use TwoZeroFourEightWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", TwoZeroFourEightWeb do
    pipe_through :browser

    post("/find_game", GameController, :find_game)
    resources("/", GameController, only: [:index, :new, :create, :show])
  end
end
