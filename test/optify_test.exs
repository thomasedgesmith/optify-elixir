defmodule OptifyTest do
  use ExUnit.Case, async: true

  alias Optify.GetOptionsPreferences

  @configs Path.expand("fixtures/configs", __DIR__)

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
end
