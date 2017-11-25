defmodule MinimalPlug do
  use Application

  def start(_type, _args) do
    Plug.Adapters.Cowboy.http(MinimalPlug.Router, [], port: 8080)
  end
end


defmodule MinimalPlug.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> send_resp(200, "Hello, world!")
  end
end
