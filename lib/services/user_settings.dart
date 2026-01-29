import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const String _themeModeKey = 'theme_mode';
  static const String _collectionAskedPrefix = 'collection_download_asked_';
  static const String _favoritesKey = 'favorite_song_ids';

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

  Future<List<String>> getFavoriteSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> setFavoriteSongIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids);
  }
}
