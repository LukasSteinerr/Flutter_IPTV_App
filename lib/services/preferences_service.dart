import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _firstLaunchKey = 'first_launch';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _hasActivePlaylistKey = 'has_active_playlist';
  static const String _selectedThemeKey = 'selected_theme';
  static const String _epgUrlKey = 'epg_url';

  // Singleton instance
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _preferences;
  
  Future<SharedPreferences> get preferences async {
    _preferences ??= await SharedPreferences.getInstance();
    return _preferences!;
  }

  // Check if this is the first launch of the app
  Future<bool> isFirstLaunch() async {
    final prefs = await preferences;
    bool isFirst = prefs.getBool(_firstLaunchKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return isFirst;
  }

  // Get/set onboarding completion status
  Future<bool> isOnboardingComplete() async {
    final prefs = await preferences;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await preferences;
    await prefs.setBool(_onboardingCompleteKey, complete);
  }

  // Get/set whether user has added at least one playlist
  Future<bool> hasActivePlaylist() async {
    final prefs = await preferences;
    return prefs.getBool(_hasActivePlaylistKey) ?? false;
  }

  Future<void> setHasActivePlaylist(bool hasPlaylist) async {
    final prefs = await preferences;
    await prefs.setBool(_hasActivePlaylistKey, hasPlaylist);
  }

  // Get/set selected app theme
  Future<String> getSelectedTheme() async {
    final prefs = await preferences;
    return prefs.getString(_selectedThemeKey) ?? 'dark';
  }

  Future<void> setSelectedTheme(String theme) async {
    final prefs = await preferences;
    await prefs.setString(_selectedThemeKey, theme);
  }

  // Get/set EPG URL
  Future<String?> getEpgUrl() async {
    final prefs = await preferences;
    return prefs.getString(_epgUrlKey);
  }

  Future<void> setEpgUrl(String url) async {
    final prefs = await preferences;
    await prefs.setString(_epgUrlKey, url);
  }
}