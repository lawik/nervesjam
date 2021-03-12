# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nervespub,
  ecto_repos: [Nervespub.Repo]

config :nervespub, Nervespub.Repo,
  database: "database.db",
  show_sensitive_data_on_connection_error: false,
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 1

# Configures the endpoint
config :nervespub, NervespubWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "baDOVaHswr8Q0T3IZjU1ujS4AZLUT+FVQvIHaQMr+prGf3LZn9/H6ioBCJ8bXHN2",
  render_errors: [view: NervespubWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Nervespub.PubSub,
  live_view: [signing_salt: "C0x9UdTb"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
