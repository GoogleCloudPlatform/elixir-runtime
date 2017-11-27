defmodule MinimalPhoenixWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :minimal_phoenix

  plug Plug.Static,
    at: "/", from: :minimal_phoenix, gzip: false,
    only: ~w(css fonts images js)

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.MethodOverride
  plug Plug.Head

  plug MinimalPhoenixWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
