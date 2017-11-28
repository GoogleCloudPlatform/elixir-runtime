defmodule MinimalPhoenixWeb.Router do
  use MinimalPhoenixWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/", MinimalPhoenixWeb do
    pipe_through :browser
    get "/", PageController, :index
    get "/elixir-version", PageController, :elixir_version
  end
end
