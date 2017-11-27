use Mix.Config

config :minimal_phoenix, MinimalPhoenixWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1MIcAd9Ed+HHVwG5oQhUlBsPa+BPbSdQWtZ3JHDMyRdpZllMAf7xc7piPGjlCrFB"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env}.exs"
