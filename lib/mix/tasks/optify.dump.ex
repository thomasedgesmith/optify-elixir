defmodule Mix.Tasks.Optify.Dump do
  use Mix.Task

  alias Optify.GetOptionsPreferences

  @shortdoc "Dump resolved Optify config for a feature"
  @requirements ["app.start"]

  @switches [
    output: :string,
    key: :string,
    constraints_file: :string,
    constraints_json: :string
  ]
  @aliases [o: :output, k: :key]

  @moduledoc """
  Dump the resolved Optify config for a single feature.

  This task uses the application's configured Optify provider from `config/runtime.exs`
  or other app config, resolves the given feature name or alias, applies imports, and
  prints the merged result as pretty JSON.

  ## Examples

      mix optify.dump feature_a
      mix optify.dump A --output tmp/feature_a.json
      mix optify.dump feature_a --key flow
      mix optify.dump feature_conditioned --constraints-file tmp/constraints.json

  """

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches, aliases: @aliases)

    validate_args!(positional, invalid, opts)

    [feature_name] = positional
    provider = default_provider!()
    canonical_feature_name = canonical_feature_name!(provider, feature_name)
    preferences = build_preferences(opts)

    ensure_feature_included!(provider, canonical_feature_name, preferences)

    json =
      case opts[:key] do
        nil ->
          Optify.get_all_options_json!(provider, [canonical_feature_name], preferences)

        key ->
          Optify.get_options_json!(provider, key, [canonical_feature_name], preferences)
      end

    write_output(pretty_json(json), opts[:output])
  end

  defp validate_args!([_feature_name], [], opts) do
    if opts[:constraints_file] && opts[:constraints_json] do
      Mix.raise("Use either --constraints-file or --constraints-json, not both")
    end
  end

  defp validate_args!(positional, invalid, _opts) do
    invalid_args =
      invalid
      |> Enum.map(fn
        {switch, nil} -> "--#{switch}"
        {switch, value} -> "--#{switch}=#{value}"
      end)

    cond do
      invalid_args != [] ->
        Mix.raise("Invalid options: #{Enum.join(invalid_args, ", ")}")

      positional == [] ->
        Mix.raise("Expected a feature name. Usage: mix optify.dump FEATURE_NAME")

      true ->
        Mix.raise("Expected exactly one feature name. Usage: mix optify.dump FEATURE_NAME")
    end
  end

  defp canonical_feature_name!(provider, feature_name) do
    case Optify.get_canonical_feature_name(provider, feature_name) do
      {:ok, canonical_feature_name} ->
        canonical_feature_name

      {:error, reason} ->
        Mix.raise("Unable to resolve feature #{inspect(feature_name)}: #{reason}")
    end
  end

  defp default_provider! do
    case Optify.default_provider() do
      nil -> Optify.load_default_provider!()
      provider -> provider
    end
  end

  defp build_preferences(opts) do
    %GetOptionsPreferences{
      constraints_json: constraints_json(opts)
    }
  end

  defp constraints_json(opts) do
    cond do
      path = opts[:constraints_file] ->
        File.read!(path)

      json = opts[:constraints_json] ->
        json

      true ->
        nil
    end
  end

  defp ensure_feature_included!(provider, canonical_feature_name, preferences) do
    case Optify.get_filtered_feature_names(provider, [canonical_feature_name], preferences) do
      {:ok, []} ->
        Mix.raise(
          "Feature #{inspect(canonical_feature_name)} was filtered out by the provided constraints"
        )

      {:ok, [_]} ->
        :ok

      {:error, reason} ->
        Mix.raise("Unable to resolve filtered features: #{reason}")
    end
  end

  defp pretty_json(json), do: Jason.Formatter.pretty_print(json) <> "\n"

  defp write_output(output, nil), do: IO.write(output)

  defp write_output(output, path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, output)
    Mix.shell().info("Wrote #{path}")
  end
end
