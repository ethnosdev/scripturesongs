import 'package:flutter/material.dart';
import 'package:scripturesongs/services/user_settings.dart';

class AppState {
  final UserSettings _settingsService;
  late final ValueNotifier<ThemeMode> currentTheme;

  AppState(this._settingsService) {
    currentTheme = ValueNotifier(ThemeMode.system);
    _loadTheme();
  }

  void _loadTheme() async {
    currentTheme.value = await _settingsService.getThemeMode();
  }

  void updateTheme(ThemeMode themeMode) {
    currentTheme.value = themeMode;
    _settingsService.setThemeMode(themeMode);
  }
}
