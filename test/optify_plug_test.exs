defmodule Optify.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  @configs Path.expand("fixtures/configs", __DIR__)

  test "assigns options onto conn" do
    {:ok, provider} = Optify.build(@configs)

    conn =
      :get
      |> conn("/")
      |> assign(:features, ["A", "B"])
      |> Optify.Plug.call(
        Optify.Plug.init(
          provider: provider,
          key: "myConfig",
          feature_names: fn conn -> conn.assigns.features end,
          assign: :my_config
        )
      )

    assert conn.assigns.my_config["handler"] == "b"
  end
end
