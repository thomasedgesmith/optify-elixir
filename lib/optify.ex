defmodule Optify do
  @moduledoc """
  Elixir client for Optify backed by the upstream Rust crate.

  This module exposes the main provider APIs and returns Elixir maps by default.
  """

  alias Optify.GetOptionsPreferences
  alias Optify.Native

  @type provider :: reference()

  @doc """
  Build a provider from one config directory.
  """
  @spec build(String.t()) :: {:ok, provider()} | {:error, String.t()}
  def build(directory), do: Native.build_provider(directory)

  @doc """
  Build a provider from multiple config directories.
  """
  @spec build_from_directories([String.t()]) :: {:ok, provider()} | {:error, String.t()}
  def build_from_directories(directories), do: Native.build_provider_from_directories(directories)

  @spec features(provider()) :: [String.t()]
  def features(provider), do: Native.features(provider)

  @spec get_canonical_feature_name(provider(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_canonical_feature_name(provider, feature_name),
    do: Native.get_canonical_feature_name(provider, feature_name)

  @spec get_canonical_feature_names(provider(), [String.t()]) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_canonical_feature_names(provider, feature_names),
    do: Native.get_canonical_feature_names(provider, feature_names)

  @doc """
  Get options and decode the returned JSON into Elixir terms.
  """
  @spec get_options(provider(), String.t(), [String.t()], GetOptionsPreferences.t()) ::
          {:ok, map() | list() | String.t() | number() | boolean() | nil} | {:error, String.t()}
  def get_options(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    with {:ok, json} <-
           Native.get_options_json_with_preferences(
             provider,
             key,
             feature_names,
             GetOptionsPreferences.to_nif_map(preferences)
           ),
         {:ok, decoded} <- Jason.decode(json) do
      {:ok, decoded}
    else
      {:error, reason} when is_binary(reason) -> {:error, reason}
      {:error, %Jason.DecodeError{} = err} -> {:error, Exception.message(err)}
    end
  end

  @doc """
  Same as `get_options/4` but returns the value directly and raises on failure.
  """
  @spec get_options!(provider(), String.t(), [String.t()], GetOptionsPreferences.t()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_options!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options(provider, key, feature_names, preferences) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_options!/4 failed: #{reason}"
    end
  end

  @doc """
  Get options as raw JSON.
  """
  @spec get_options_json(provider(), String.t(), [String.t()], GetOptionsPreferences.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_options_json(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    Native.get_options_json_with_preferences(
      provider,
      key,
      feature_names,
      GetOptionsPreferences.to_nif_map(preferences)
    )
  end

  @doc """
  Same as `get_options_json/4` but returns JSON directly and raises on failure.
  """
  @spec get_options_json!(provider(), String.t(), [String.t()], GetOptionsPreferences.t()) ::
          String.t()
  def get_options_json!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options_json(provider, key, feature_names, preferences) do
      {:ok, json} -> json
      {:error, reason} -> raise ArgumentError, "Optify.get_options_json!/4 failed: #{reason}"
    end
  end
end
