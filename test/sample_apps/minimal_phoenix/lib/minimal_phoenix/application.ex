defmodule MinimalPhoenix.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [supervisor(MinimalPhoenixWeb.Endpoint, [])]
    opts = [strategy: :one_for_one, name: MinimalPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    MinimalPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
