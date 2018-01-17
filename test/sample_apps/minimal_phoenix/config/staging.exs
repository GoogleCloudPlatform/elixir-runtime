use Mix.Config

config :minimal_phoenix, MinimalPhoenixWeb.Endpoint,
  load_from_system_env: true,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
# config :minimal_phoenix, MinimalPhoenixWeb.Endpoint, server: true

config :minimal_phoenix, test_output: "from staging"
