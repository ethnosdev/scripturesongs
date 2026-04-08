import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const String _themeModeKey = 'theme_mode';
  static const String _collectionAskedPrefix = 'collection_download_asked_';
  static const String _favoritesKey = 'favorite_song_ids';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _preferredVersionPrefix = 'pref_version_';
  static const String _lastCollectionKey = 'last_collection';
  static const String _lastTrackKey = 'last_track';
  static const String _lastPositionKey = 'last_position_ms';

  // --- Theme ---
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeModeString);
  }

  // --- Downloads ---
  Future<bool> hasAskedToDownloadCollection(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_collectionAskedPrefix$collection';
    return prefs.getBool(key) ?? false;
  }

  Future<void> setAskedToDownloadCollection(
    String collection,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_collectionAskedPrefix$collection';
    await prefs.setBool(key, value);
  }

  // --- Favorites ---
  Future<List<String>> getFavoriteSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> setFavoriteSongIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids);
  }

  // --- Onboarding ---
  Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  // --- Versions ---
  Future<String?> getPreferredVersion(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_preferredVersionPrefix$trackId');
  }

  Future<void> setPreferredVersion(String trackId, String versionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_preferredVersionPrefix$trackId', versionId);
  }

  // --- Playback State ---
  Future<void> savePlaybackState(
    String collectionId,
    String trackId,
    Duration position,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCollectionKey, collectionId);
    await prefs.setString(_lastTrackKey, trackId);
    await prefs.setInt(_lastPositionKey, position.inMilliseconds);
  }

  Future<Map<String, dynamic>?> getPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionId = prefs.getString(_lastCollectionKey);
    final trackId = prefs.getString(_lastTrackKey);
    final positionMs = prefs.getInt(_lastPositionKey);

    if (collectionId != null && trackId != null && positionMs != null) {
      return {
        'collectionId': collectionId,
        'trackId': trackId,
        'position': Duration(milliseconds: positionMs),
      };
    }
    return null;
  }
}
