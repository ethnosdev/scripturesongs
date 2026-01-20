import 'package:get_it/get_it.dart';
import 'package:scripturesongs/core/app_state.dart';
import 'package:scripturesongs/core/services/api_service.dart';
import 'package:scripturesongs/core/services/audio_manager.dart';
import 'package:scripturesongs/core/services/settings_service.dart';
import 'package:scripturesongs/features/home/home_manager.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<ApiService>(() => ApiService());
  locator.registerLazySingleton<SettingsService>(() => SettingsService());
  locator.registerLazySingleton<AppState>(() => AppState(locator<SettingsService>()));
  locator.registerLazySingleton<AudioManager>(() => AudioManager());
  locator.registerFactory<HomeManager>(() => HomeManager());
}