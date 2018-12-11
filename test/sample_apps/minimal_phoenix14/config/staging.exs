use Mix.Config

config :minimal_phoenix14, MinimalPhoenix14Web.Endpoint,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
#config :minimal_phoenix14, MinimalPhoenix14Web.Endpoint, server: true

config :minimal_phoenix14, test_output: "from staging"
