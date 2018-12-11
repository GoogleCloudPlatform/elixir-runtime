defmodule MinimalPhoenix14Web.Router do
  use MinimalPhoenix14Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", MinimalPhoenix14Web do
    pipe_through :browser
    get "/", PageController, :index
    get "/elixir-version", PageController, :elixir_version
  end
end
