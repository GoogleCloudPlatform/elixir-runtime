defmodule MinimalPhoenixWeb.PageController do
  use MinimalPhoenixWeb, :controller

  def index(conn, _params) do
    text conn, "Hello, world!"
  end

  def elixir_version(conn, _params) do
    text conn, System.version
  end
end
