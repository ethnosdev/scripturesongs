import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const String _themeModeKey = 'theme_mode';
  static const String _collectionAskedKey = 'collection_download_asked';

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

  Future<bool> hasAskedToDownloadCollection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_collectionAskedKey) ?? false;
  }

  Future<void> setAskedToDownloadCollection(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collectionAskedKey, value);
  }
}
