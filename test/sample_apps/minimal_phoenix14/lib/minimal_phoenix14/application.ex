defmodule MinimalPhoenix14.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [MinimalPhoenix14Web.Endpoint]
    opts = [strategy: :one_for_one, name: MinimalPhoenix14.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    MinimalPhoenix14Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
