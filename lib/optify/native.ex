defmodule Optify.Native do
  @moduledoc false

  use Rustler, otp_app: :optify, crate: "optify_nif"

  def build_provider(_directory), do: :erlang.nif_error(:nif_not_loaded)
  def build_provider_with_schema(_directory, _schema_path), do: :erlang.nif_error(:nif_not_loaded)
  def build_provider_from_directories(_directories), do: :erlang.nif_error(:nif_not_loaded)

  def build_provider_from_directories_with_schema(_directories, _schema_path),
    do: :erlang.nif_error(:nif_not_loaded)

  def features(_provider), do: :erlang.nif_error(:nif_not_loaded)
  def get_aliases(_provider), do: :erlang.nif_error(:nif_not_loaded)
  def get_features_and_aliases(_provider), do: :erlang.nif_error(:nif_not_loaded)
  def get_canonical_feature_name(_provider, _feature_name), do: :erlang.nif_error(:nif_not_loaded)

  def get_canonical_feature_names(_provider, _feature_names),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_feature_metadata_json(_provider, _canonical_feature_name),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_features_with_metadata_json(_provider), do: :erlang.nif_error(:nif_not_loaded)

  def get_filtered_feature_names(_provider, _feature_names, _preferences),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_options_json_with_preferences(_provider, _key, _feature_names, _preferences),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_all_options_json_with_preferences(_provider, _feature_names, _preferences),
    do: :erlang.nif_error(:nif_not_loaded)

  def has_conditions(_provider, _canonical_feature_name), do: :erlang.nif_error(:nif_not_loaded)
end