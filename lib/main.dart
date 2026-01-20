import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scripturesongs/core/app_state.dart';
import 'package:scripturesongs/core/service_locator.dart';
import 'package:scripturesongs/features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ethnosdev.scripturesongs.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = locator<AppState>();
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
