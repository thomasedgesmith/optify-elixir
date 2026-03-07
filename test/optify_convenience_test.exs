defmodule Optify.ConvenienceTest do
  use ExUnit.Case, async: false

  @configs Path.expand("fixtures/configs", __DIR__)

  defmodule FlowOptions do
    defstruct [:handler, :timeout_ms]

    def from_optify(%{flow: flow}) do
      struct(__MODULE__, flow)
    end
  end

  defmodule NestedFlowOptions do
    defstruct [:handler, :timeout_ms]
  end

  defmodule AppOptions do
    defstruct flow: %NestedFlowOptions{}
  end

  test "get_options!/1 uses default provider and atom keys for dot access" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["A", "B"])

    assert options.flow.handler == "b"
    assert options.flow.timeout_ms == 200
  end

  test "get_options!/1 hydrates known nested option paths with nil defaults" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["feature_conditioned"])

    assert options.myConfig.conditioned
    assert options.flow.handler == nil
    assert options.flow.timeout_ms == nil
  end

  test "get_options/1 hydrates known nested option paths with nil defaults" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    assert {:ok, options} = Optify.get_options(["feature_conditioned"])

    assert options.myConfig.conditioned
    assert options.flow.handler == nil
    assert options.flow.timeout_ms == nil
  end

  test "get_options!/2 hydrates known nested option paths for string keys too" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["feature_conditioned"], keys: :strings)

    assert options["myConfig"]["conditioned"]
    assert options["flow"]["handler"] == nil
    assert options["flow"]["timeout_ms"] == nil
  end

  test "get_options/2 hydrates known nested option paths for string keys too" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    assert {:ok, options} = Optify.get_options(["feature_conditioned"], keys: :strings)

    assert options["myConfig"]["conditioned"]
    assert options["flow"]["handler"] == nil
    assert options["flow"]["timeout_ms"] == nil
  end

  test "get_options!/2 can cast to a struct module" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    flow = Optify.get_options!(["A", "B"], as: FlowOptions)
    assert %FlowOptions{handler: "b", timeout_ms: 200} = flow
  end

  test "automatic struct casting supports nested defaults for present data" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["A"], as: AppOptions)

    assert %AppOptions{flow: %NestedFlowOptions{handler: "a", timeout_ms: 100}} = options
    assert options.flow.handler == "a"
  end

  test "automatic struct casting keeps nested struct defaults when a parent is missing" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["feature_conditioned"], as: AppOptions)

    assert %AppOptions{flow: %NestedFlowOptions{handler: nil, timeout_ms: nil}} = options
    assert options.flow.handler == nil
  end

  test "automatic struct casting keeps nested struct defaults when a parent is nil" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options =
      Optify.get_options!(["A"],
        as: AppOptions,
        preferences: %{
          overrides: %{
            flow: nil
          }
        }
      )

    assert %AppOptions{flow: %NestedFlowOptions{handler: nil, timeout_ms: nil}} = options
    assert options.flow.handler == nil
  end

  test "provider introspection can use the default provider" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    assert Enum.sort(Optify.get_features()) ==
             Enum.sort(["feature_a", "feature_b", "feature_conditioned"])

    assert Enum.sort(Optify.get_aliases()) == ["A", "B"]

    assert Enum.sort(Optify.get_features_and_aliases()) ==
             Enum.sort(["A", "B", "feature_a", "feature_b", "feature_conditioned"])

    assert Optify.get_canonical_feature_name!("A") == "feature_a"
    assert Optify.get_canonical_feature_names!(["A", "b"]) == ["feature_a", "feature_b"]

    metadata = Optify.get_feature_metadata("feature_a")
    assert metadata["owners"] == "team-a@example.com"

    metadata_by_feature = Optify.get_features_with_metadata()
    assert metadata_by_feature["feature_b"]["owners"] == "team-b@example.com"

    assert Optify.get_filtered_feature_names!(["A", "feature_conditioned"], %{
             constraints_json: ~s({"clientId":1234})
           }) == ["feature_a", "feature_conditioned"]

    assert Optify.has_conditions("feature_conditioned")
    refute Optify.has_conditions("feature_a")
  end
end
