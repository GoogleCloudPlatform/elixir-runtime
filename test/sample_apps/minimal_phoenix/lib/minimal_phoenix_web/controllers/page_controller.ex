defmodule MinimalPhoenixWeb.PageController do
  use MinimalPhoenixWeb, :controller

  def index(conn, _params) do
    text conn, "Hello, world!"
  end
end
