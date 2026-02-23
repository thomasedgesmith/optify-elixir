import Config

config :optify, Optify.Native,
  crate: :optify_nif,
  path: "native/optify_nif",
  mode: if(config_env() == :prod, do: :release, else: :debug)

# Defaults: provider loads at app startup and auto-reloads in dev.
config :optify, :auto_load_default_provider, true
config :optify, :auto_reload_default_provider, config_env() == :dev

# Optional provider build config used by Optify.build_from_config/0 and /!/0
# config :optify, :provider,
#   directory: "config/optify"
#
# Or multiple directories:
# config :optify, :provider,
#   directories: ["config/optify", "config/optify_shared"]
