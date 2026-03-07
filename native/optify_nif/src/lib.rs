use optify::provider::{GetOptionsPreferences, OptionsProvider, OptionsRegistry};
use rustler::{Env, NifMap, ResourceArc, Term};

struct ProviderResource {
    provider: OptionsProvider,
}

#[derive(NifMap)]
struct PreferencesInput {
    are_configurable_strings_enabled: Option<bool>,
    constraints_json: Option<String>,
    overrides_json: Option<String>,
    skip_feature_name_conversion: Option<bool>,
}

#[rustler::nif]
fn build_provider(directory: String) -> Result<ResourceArc<ProviderResource>, String> {
    OptionsProvider::build(directory)
        .map(|provider| ResourceArc::new(ProviderResource { provider }))
}

#[rustler::nif]
fn build_provider_with_schema(
    directory: String,
    schema_path: String,
) -> Result<ResourceArc<ProviderResource>, String> {
    OptionsProvider::build_with_schema(directory, schema_path)
        .map(|provider| ResourceArc::new(ProviderResource { provider }))
}

#[rustler::nif]
fn build_provider_from_directories(
    directories: Vec<String>,
) -> Result<ResourceArc<ProviderResource>, String> {
    OptionsProvider::build_from_directories(&directories)
        .map(|provider| ResourceArc::new(ProviderResource { provider }))
}

#[rustler::nif]
fn build_provider_from_directories_with_schema(
    directories: Vec<String>,
    schema_path: String,
) -> Result<ResourceArc<ProviderResource>, String> {
    OptionsProvider::build_from_directories_with_schema(&directories, schema_path)
        .map(|provider| ResourceArc::new(ProviderResource { provider }))
}

#[rustler::nif]
fn features(provider: ResourceArc<ProviderResource>) -> Vec<String> {
    provider.provider.get_features()
}

#[rustler::nif]
fn get_aliases(provider: ResourceArc<ProviderResource>) -> Vec<String> {
    provider.provider.get_aliases()
}

#[rustler::nif]
fn get_features_and_aliases(provider: ResourceArc<ProviderResource>) -> Vec<String> {
    provider.provider.get_features_and_aliases()
}

#[rustler::nif]
fn get_canonical_feature_name(
    provider: ResourceArc<ProviderResource>,
    feature_name: String,
) -> Result<String, String> {
    provider.provider.get_canonical_feature_name(&feature_name)
}

#[rustler::nif]
fn get_canonical_feature_names(
    provider: ResourceArc<ProviderResource>,
    feature_names: Vec<String>,
) -> Result<Vec<String>, String> {
    provider
        .provider
        .get_canonical_feature_names(&feature_names)
}

#[rustler::nif]
fn get_feature_metadata_json(
    provider: ResourceArc<ProviderResource>,
    canonical_feature_name: String,
) -> Option<String> {
    provider
        .provider
        .get_feature_metadata(&canonical_feature_name)
        .map(|metadata| serde_json::to_string(&metadata).expect("metadata should serialize"))
}

#[rustler::nif]
fn get_features_with_metadata_json(provider: ResourceArc<ProviderResource>) -> String {
    serde_json::to_string(&provider.provider.get_features_with_metadata())
        .expect("features metadata should serialize")
}

fn make_preferences(preferences: PreferencesInput) -> Result<GetOptionsPreferences, String> {
    let mut prefs = GetOptionsPreferences::new();

    if preferences
        .are_configurable_strings_enabled
        .unwrap_or(false)
    {
        prefs.are_configurable_strings_enabled = true;
    }

    if let Some(skip) = preferences.skip_feature_name_conversion {
        prefs.skip_feature_name_conversion = skip;
    }

    if let Some(constraints_json) = preferences.constraints_json.as_deref() {
        let constraints_value = serde_json::from_str(constraints_json)
            .map_err(|e| format!("Invalid constraints_json: {e}"))?;
        prefs.set_constraints(Some(constraints_value));
    }

    if let Some(overrides_json) = preferences.overrides_json.as_deref() {
        let overrides_value = serde_json::from_str(overrides_json)
            .map_err(|e| format!("Invalid overrides_json: {e}"))?;
        prefs.overrides = Some(overrides_value);
    }

    Ok(prefs)
}

#[rustler::nif]
fn get_filtered_feature_names(
    provider: ResourceArc<ProviderResource>,
    feature_names: Vec<String>,
    preferences: PreferencesInput,
) -> Result<Vec<String>, String> {
    let prefs = make_preferences(preferences)?;
    provider
        .provider
        .get_filtered_feature_names(&feature_names, Some(&prefs))
}

#[rustler::nif]
fn get_options_json_with_preferences(
    provider: ResourceArc<ProviderResource>,
    key: String,
    feature_names: Vec<String>,
    preferences: PreferencesInput,
) -> Result<String, String> {
    let prefs = make_preferences(preferences)?;

    provider
        .provider
        .get_options_with_preferences(&key, &feature_names, None, Some(&prefs))
        .map(|value| value.to_string())
}

#[rustler::nif]
fn get_all_options_json_with_preferences(
    provider: ResourceArc<ProviderResource>,
    feature_names: Vec<String>,
    preferences: PreferencesInput,
) -> Result<String, String> {
    let prefs = make_preferences(preferences)?;

    provider
        .provider
        .get_all_options(&feature_names, None, Some(&prefs))
        .map(|value| value.to_string())
}

#[rustler::nif]
fn has_conditions(provider: ResourceArc<ProviderResource>, canonical_feature_name: String) -> bool {
    provider.provider.has_conditions(&canonical_feature_name)
}

fn load(env: Env, _info: Term) -> bool {
    let _ = rustler::resource!(ProviderResource, env);
    true
}

rustler::init!("Elixir.Optify.Native", load = load);
