import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scripturesongs/app_state.dart';
import 'package:scripturesongs/services/download_manager.dart';
import 'package:scripturesongs/services/migration_service.dart';
import 'package:scripturesongs/services/service_locator.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';
import 'package:scripturesongs/ui/home/home_screen.dart';
import 'package:scripturesongs/ui/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ethnosdev.scripturesongs.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  setupLocator();

  // TODO: delete the migration service after a time.
  await getIt<MigrationService>().runMigration();

  await getIt<DownloadManager>().init();
  await getIt<HomeManager>().init();

  final userSettings = getIt<UserSettings>();
  final hasSeenOnboarding = await userSettings.getHasSeenOnboarding();

  runApp(MyApp(showOnboarding: !hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    final appState = getIt<AppState>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appState.currentTheme,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Scripture Songs',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
        );
      },
    );
  }
}
