import 'package:flutter/material.dart';
import 'package:scripturesongs/app_state.dart';
import 'package:scripturesongs/services/service_locator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: appState.currentTheme,
        builder: (context, themeMode, _) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Light-Dark Theme'),
                subtitle: Text(
                  themeMode == ThemeMode.light
                      ? 'Light'
                      : themeMode == ThemeMode.dark
                      ? 'Dark'
                      : 'Match device settings',
                ),
                trailing: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.smartphone,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            icon: Icon(Icons.smartphone),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          appState.updateTheme(selection.first);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
