defmodule OptifyTest do
  use ExUnit.Case, async: true

  alias Optify.GetOptionsPreferences

  @configs Path.expand("fixtures/configs", __DIR__)

  test "build! returns provider directly" do
    provider = Optify.build!(@configs)
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
