defmodule Optify.GetOptionsPreferences do
  @moduledoc """
  Runtime preferences for building options.
  """

  @enforce_keys []
  defstruct are_configurable_strings_enabled: false,
            constraints_json: nil,
            overrides_json: nil,
            skip_feature_name_conversion: false

  @type t :: %__MODULE__{
          are_configurable_strings_enabled: boolean(),
          constraints_json: String.t() | nil,
          overrides_json: String.t() | nil,
          skip_feature_name_conversion: boolean()
        }

  @type input_t :: t() | map()

  @spec normalize(input_t()) :: t()
  def normalize(%__MODULE__{} = prefs), do: prefs

  def normalize(%{} = prefs) do
    %__MODULE__{
      are_configurable_strings_enabled:
        Map.get(prefs, :are_configurable_strings_enabled) ||
          Map.get(prefs, "are_configurable_strings_enabled", false),
      constraints_json:
        to_json_string(
          Map.get(prefs, :constraints_json) ||
            Map.get(prefs, "constraints_json") ||
            Map.get(prefs, :constraints) ||
            Map.get(prefs, "constraints")
        ),
      overrides_json:
        to_json_string(
          Map.get(prefs, :overrides_json) ||
            Map.get(prefs, "overrides_json") ||
            Map.get(prefs, :overrides) ||
            Map.get(prefs, "overrides")
        ),
      skip_feature_name_conversion:
        Map.get(prefs, :skip_feature_name_conversion) ||
          Map.get(prefs, "skip_feature_name_conversion", false)
    }
  end

  @spec to_nif_map(input_t()) :: map()
  def to_nif_map(prefs) do
    prefs = normalize(prefs)

    %{
      are_configurable_strings_enabled: prefs.are_configurable_strings_enabled,
      constraints_json: prefs.constraints_json,
      overrides_json: prefs.overrides_json,
      skip_feature_name_conversion: prefs.skip_feature_name_conversion
    }
  end

  defp to_json_string(nil), do: nil
  defp to_json_string(value) when is_binary(value), do: value

  defp to_json_string(value) do
    Jason.encode!(value)
  end
end
