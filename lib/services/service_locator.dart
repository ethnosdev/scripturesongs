import 'package:get_it/get_it.dart';
import 'package:scripturesongs/app_state.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<ApiService>(() => ApiService());
  locator.registerLazySingleton<UserSettings>(() => UserSettings());
  locator.registerLazySingleton<AppState>(
    () => AppState(locator<UserSettings>()),
  );
  locator.registerLazySingleton<AudioManager>(() => AudioManager());
  locator.registerFactory<HomeManager>(() => HomeManager());
}
