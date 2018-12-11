use Mix.Config

config :minimal_phoenix14, MinimalPhoenix14Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "02GHEyqgil/1v13KZ02jtj7/fyITF6r/1CsOcWxmGwHPY7BWsIAYEQurgFN8or/q",
  render_errors: [view: MinimalPhoenix14Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MinimalPhoenix14.PubSub, adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
