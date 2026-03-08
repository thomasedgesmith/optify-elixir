defmodule Optify.Native do
  @moduledoc false

  version = File.read!(Path.expand("../../VERSION", __DIR__)) |> String.trim()

  supported_targets = [
    "aarch64-apple-darwin",
    "x86_64-apple-darwin",
    "aarch64-unknown-linux-gnu",
    "x86_64-unknown-linux-gnu"
  ]

  supported_nif_versions = ["2.16"]

  current_target =
    case RustlerPrecompiled.target() do
      {:ok, target} ->
        [_prefix, _nif_version, target_triple] = String.split(target, "-", parts: 3)
        target_triple

      {:error, _reason} ->
        nil
    end

  compatible_nif? =
    case String.split(:erlang.system_info(:nif_version) |> List.to_string(), ".") do
      [current_major, current_minor] ->
        Enum.any?(supported_nif_versions, fn supported_nif_version ->
          case String.split(supported_nif_version, ".") do
            [supported_major, supported_minor] ->
              current_major == supported_major and
                String.to_integer(current_minor) >= String.to_integer(supported_minor)

            _ ->
              false
          end
        end)

      _ ->
        false
    end

  force_build =
    System.get_env("OPTIFY_BUILD") in ["1", "true"] or
      current_target not in supported_targets or not compatible_nif?

  use RustlerPrecompiled,
    otp_app: :optify,
    crate: "optify_nif",
    base_url: "https://github.com/thomasedgesmith/optify-elixir/releases/download/v#{version}",
    force_build: force_build,
    nif_versions: supported_nif_versions,
    targets: supported_targets,
    version: version

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
