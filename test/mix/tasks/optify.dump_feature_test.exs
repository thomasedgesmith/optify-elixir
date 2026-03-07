defmodule Mix.Tasks.Optify.DumpFeatureTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "optify.dump_feature"
  @configs Path.expand("../../fixtures/dump_feature_configs", __DIR__)

  setup do
    Application.ensure_all_started(:optify)

    old_config = Application.get_env(:optify, :provider)
    old_provider = Optify.default_provider()

    Application.put_env(:optify, :provider, directory: @configs)
    :ok = Optify.set_default_provider(nil)
    Mix.Task.clear()

    on_exit(fn ->
      if old_config == nil do
        Application.delete_env(:optify, :provider)
      else
        Application.put_env(:optify, :provider, old_config)
      end

      :ok = Optify.set_default_provider(old_provider)
      Mix.Task.clear()
    end)

    :ok
  end

  test "dumps the resolved feature using the configured default provider" do
    output =
      capture_io(fn ->
        Mix.Task.run(@task, ["COMPOSED"])
      end)

    assert Jason.decode!(output) == %{
             "flow" => %{
               "handler" => "composed",
               "retries" => 3,
               "timeout_ms" => 150
             },
             "notifications" => %{
               "channel" => "email",
               "enabled" => true
             }
           }

    assert is_reference(Optify.default_provider())
  end

  test "supports dumping a specific top-level key to a file" do
    provider = Optify.build!(@configs)
    :ok = Optify.set_default_provider(provider)

    path =
      Path.join(
        System.tmp_dir!(),
        "optify_dump_feature_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(path)
    end)

    capture_io(fn ->
      Mix.Task.run(@task, ["feature_composed", "--key", "flow", "--output", path])
    end)

    assert Jason.decode!(File.read!(path)) == %{
             "handler" => "composed",
             "retries" => 3,
             "timeout_ms" => 150
           }
  end
end
