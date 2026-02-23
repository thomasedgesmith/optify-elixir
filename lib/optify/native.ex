defmodule Optify.Native do
  @moduledoc false

  use Rustler, otp_app: :optify, crate: "optify_nif"

  def build_provider(_directory), do: :erlang.nif_error(:nif_not_loaded)
  def build_provider_from_directories(_directories), do: :erlang.nif_error(:nif_not_loaded)
  def features(_provider), do: :erlang.nif_error(:nif_not_loaded)
  def get_canonical_feature_name(_provider, _feature_name), do: :erlang.nif_error(:nif_not_loaded)

  def get_canonical_feature_names(_provider, _feature_names),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_options_json_with_preferences(_provider, _key, _feature_names, _preferences),
    do: :erlang.nif_error(:nif_not_loaded)
end
