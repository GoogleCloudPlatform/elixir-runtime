defmodule MinimalPhoenix14Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :minimal_phoenix14

  plug Plug.Static,
    at: "/",
    from: :minimal_phoenix14,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_minimal_phoenix14_key",
    signing_salt: "JDc3EJG2"

  plug MinimalPhoenix14Web.Router
end
