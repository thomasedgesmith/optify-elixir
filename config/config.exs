import Config

config :optify, Optify.Native,
  crate: :optify_nif,
  path: "native/optify_nif",
  mode: if(config_env() == :prod, do: :release, else: :debug)
