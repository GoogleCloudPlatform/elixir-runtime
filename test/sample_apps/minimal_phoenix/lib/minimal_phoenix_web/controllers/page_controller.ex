defmodule MinimalPhoenixWeb.PageController do
  use MinimalPhoenixWeb, :controller

  def index(conn, _params) do
    default_output = "Hello, world!"
    output = Application.get_env(:minimal_phoenix, :test_output, default_output)
    text conn, output
  end

  def elixir_version(conn, _params) do
    text conn, System.version
  end
end
