use Mix.Config

config :minimal_phoenix14, MinimalPhoenix14Web.Endpoint,
  load_from_system_env: true,
  http: [:inet6, port: {:system, "PORT"}],
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :phoenix, :serve_endpoints, true
#config :minimal_phoenix14, MinimalPhoenix14Web.Endpoint, server: true
