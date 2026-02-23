defmodule Optify.ConvenienceTest do
  use ExUnit.Case, async: false

  @configs Path.expand("fixtures/configs", __DIR__)

  defmodule FlowOptions do
    defstruct [:handler, :timeout_ms]

    def from_optify(%{flow: flow}) do
      struct(__MODULE__, flow)
    end
  end

  test "get_options!/1 uses default provider and atom keys for dot access" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    options = Optify.get_options!(["A", "B"])

    assert options.flow.handler == "b"
    assert options.flow.timeout_ms == 200
  end

  test "get_options!/2 can cast to a struct module" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    flow = Optify.get_options!(["A", "B"], as: FlowOptions)
    assert %FlowOptions{handler: "b", timeout_ms: 200} = flow
  end
end
