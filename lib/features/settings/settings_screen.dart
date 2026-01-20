import 'package:flutter/material.dart';
import 'package:scripturesongs/core/app_state.dart';
import 'package:scripturesongs/core/service_locator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = locator<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: appState.currentTheme,
              builder: (context, themeMode, _) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.updateTheme(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.updateTheme(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.updateTheme(value);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
