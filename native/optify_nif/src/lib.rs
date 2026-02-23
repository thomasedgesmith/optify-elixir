use optify::provider::{GetOptionsPreferences, OptionsProvider, OptionsRegistry};
use rustler::{Env, NifMap, ResourceArc, Term};

struct ProviderResource {
    provider: OptionsProvider,
}

#[derive(NifMap)]
struct PreferencesInput {
    are_configurable_strings_enabled: Option<bool>,
    constraints_json: Option<String>,
    skip_feature_name_conversion: Option<bool>,
}

#[rustler::nif]
fn build_provider(directory: String) -> Result<ResourceArc<ProviderResource>, String> {
    OptionsProvider::build(directory)
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
fn features(provider: ResourceArc<ProviderResource>) -> Vec<String> {
    provider.provider.get_features()
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
fn get_options_json_with_preferences(
    provider: ResourceArc<ProviderResource>,
    key: String,
    feature_names: Vec<String>,
    preferences: PreferencesInput,
) -> Result<String, String> {
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

    prefs.set_constraints_json(preferences.constraints_json.as_deref());

    provider
        .provider
        .get_options_with_preferences(&key, &feature_names, None, Some(&prefs))
        .map(|value| value.to_string())
}

fn load(env: Env, _info: Term) -> bool {
    let _ = rustler::resource!(ProviderResource, env);
    true
}

rustler::init!("Elixir.Optify.Native", load = load);
