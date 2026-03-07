defmodule OptifyTest do
  use ExUnit.Case, async: true

  alias Optify.GetOptionsPreferences

  @configs Path.expand("fixtures/configs", __DIR__)
  @schema Path.expand("fixtures/custom_feature_schema.json", __DIR__)

  test "build! returns provider directly" do
    provider = Optify.build!(@configs)
    assert is_reference(provider)
  end

  test "build_from_config! builds provider from app env config" do
    old_config = Application.get_env(:optify, :provider)

    on_exit(fn ->
      if old_config == nil do
        Application.delete_env(:optify, :provider)
      else
        Application.put_env(:optify, :provider, old_config)
      end
    end)

    Application.put_env(:optify, :provider, directory: @configs)

    provider = Optify.build_from_config!()
    assert is_reference(provider)
  end

  test "default provider auto-loads by default when provider config exists" do
    old_config = Application.get_env(:optify, :provider)
    old_auto_load = Application.get_env(:optify, :auto_load_default_provider)
    old_auto_reload = Application.get_env(:optify, :auto_reload_default_provider)

    on_exit(fn ->
      restore_env(:provider, old_config)
      restore_env(:auto_load_default_provider, old_auto_load)
      restore_env(:auto_reload_default_provider, old_auto_reload)
    end)

    Application.put_env(:optify, :provider, directory: @configs)
    Application.delete_env(:optify, :auto_load_default_provider)
    Application.put_env(:optify, :auto_reload_default_provider, false)

    assert {:ok, state} = Optify.DefaultProvider.init(%{})
    assert is_reference(state.provider)
  end

  test "build_with_schema and build_from_config! support schema validation" do
    assert {:ok, provider} = Optify.build_with_schema(@configs, @schema)
    assert is_reference(provider)

    old_config = Application.get_env(:optify, :provider)

    on_exit(fn ->
      if old_config == nil do
        Application.delete_env(:optify, :provider)
      else
        Application.put_env(:optify, :provider, old_config)
      end
    end)

    Application.put_env(:optify, :provider, directory: @configs, schema_path: @schema)

    provider = Optify.build_from_config!()
    assert is_reference(provider)
  end

  test "builds provider and returns merged options" do
    assert {:ok, provider} = Optify.build(@configs)

    assert {:ok, options} = Optify.get_options(provider, "myConfig", ["A", "B"])

    assert options["handler"] == "b"
    assert options["nested"]["one"] == 1
    assert options["nested"]["two"] == 2
    assert options["nested"]["shared"] == "from-b"
  end

  test "can fetch entire merged config without key" do
    provider = Optify.build!(@configs)

    assert {:ok, all_options} = Optify.get_all_options(provider, ["A"])
    assert all_options["myConfig"]["handler"] == "a"

    all_options_bang = Optify.get_all_options!(provider, ["B"])
    assert all_options_bang["myConfig"]["handler"] == "b"
  end

  test "canonical feature name lookup is case-insensitive" do
    assert {:ok, provider} = Optify.build(@configs)
    assert {:ok, "feature_a"} = Optify.get_canonical_feature_name(provider, "a")

    assert {:ok, ["feature_a", "feature_b"]} =
             Optify.get_canonical_feature_names(provider, ["A", "b"])
  end

  test "provider introspection methods expose aliases, metadata, and condition state" do
    provider = Optify.build!(@configs)

    assert Enum.sort(Optify.get_features(provider)) ==
             Enum.sort(["feature_a", "feature_b", "feature_conditioned"])

    assert Enum.sort(Optify.get_aliases(provider)) == ["A", "B"]

    assert Enum.sort(Optify.get_features_and_aliases(provider)) ==
             Enum.sort(["A", "B", "feature_a", "feature_b", "feature_conditioned"])

    assert Optify.has_conditions(provider, "feature_conditioned")
    refute Optify.has_conditions(provider, "feature_a")

    metadata = Optify.get_feature_metadata(provider, "feature_a")
    assert metadata["aliases"] == ["A"]
    assert metadata["details"]["summary"] == "Primary flow"
    assert metadata["owners"] == "team-a@example.com"
    assert metadata["name"] == "feature_a"
    assert String.ends_with?(metadata["path"], "test/fixtures/configs/feature_a.json")

    metadata_by_feature = Optify.get_features_with_metadata(provider)
    assert metadata_by_feature["feature_b"]["owners"] == "team-b@example.com"
  end

  test "filtered feature names apply canonical conversion and constraints" do
    provider = Optify.build!(@configs)

    assert {:ok, ["feature_a"]} =
             Optify.get_filtered_feature_names(provider, ["A"], %{})

    assert {:ok, ["feature_a"]} =
             Optify.get_filtered_feature_names(provider, ["feature_a"], %{
               skip_feature_name_conversion: true
             })

    assert {:ok, ["feature_a"]} =
             Optify.get_filtered_feature_names(provider, ["A", "feature_conditioned"], %{
               constraints: %{clientId: 999}
             })

    assert ["feature_a", "feature_conditioned"] =
             Optify.get_filtered_feature_names!(provider, ["A", "feature_conditioned"], %{
               constraints_json: ~s({"clientId":1234})
             })
  end

  test "conditions are honored with preferences constraints" do
    assert {:ok, provider} = Optify.build(@configs)

    prefs = %GetOptionsPreferences{constraints_json: ~s({"clientId":1234})}

    assert {:ok, options} =
             Optify.get_options(provider, "myConfig", ["feature_conditioned"], prefs)

    assert options["conditioned"] == true
  end

  test "overrides are accepted via map preferences" do
    provider = Optify.build!(@configs)

    assert {:ok, options} =
             Optify.get_options(provider, "myConfig", ["A"], %{
               overrides: %{
                 myConfig: %{
                   handler: "override"
                 }
               }
             })

    assert options["handler"] == "override"
  end

  defp restore_env(key, nil), do: Application.delete_env(:optify, key)
  defp restore_env(key, value), do: Application.put_env(:optify, key, value)
end
