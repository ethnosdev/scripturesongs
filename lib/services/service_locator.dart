import 'package:get_it/get_it.dart';
import 'package:scripturesongs/app_state.dart';
import 'package:scripturesongs/services/api_service.dart';
import 'package:scripturesongs/services/audio_manager.dart';
import 'package:scripturesongs/services/user_settings.dart';
import 'package:scripturesongs/ui/home/home_manager.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<UserSettings>(() => UserSettings());
  getIt.registerLazySingleton<AppState>(() => AppState(getIt<UserSettings>()));
  getIt.registerLazySingleton<AudioManager>(() => AudioManager());
  getIt.registerFactory<HomeManager>(() => HomeManager());
}
