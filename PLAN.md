Here is a comprehensive, step-by-step plan designed for an AI agent (like Cursor, Windsurf, or GitHub Copilot) to build this application.

You can feed these steps to the AI one by one to ensure accuracy and code quality.

### Project Context (Feed this to the AI first)
> **Project Goal:** Build "Scripture Songs," a Flutter music player.
> **Tech Stack:** Flutter, GetIt, ValueNotifier, Just Audio, Just Audio Background, Shared Preferences.
> **Architecture:** MVVM-style separation. `Screen` contains UI, `Manager` contains logic (using `ValueNotifier`).
> **Data:** Songs stored on Cloudflare R2.
> **Design:** Top player, bottom list. Dark/Light mode support.

---

### Step 1: Project Initialization & Dependencies
**Prompt for AI:**
Create a new Flutter project named `scripture_songs`.
1.  Update `pubspec.yaml` with the following dependencies:
    *   `just_audio`
    *   `just_audio_background`
    *   `audio_video_progress_bar`
    *   `get_it`
    *   `shared_preferences`
    *   `path_provider`
    *   `http`
    *   `share_plus`
    *   `rxdart` (for combining streams)
    *   `permission_handler` (for downloads)
2.  Set up the folder structure in `lib/`:
    *   `core/` (services, locator, theme)
    *   `models/`
    *   `features/home/`
    *   `features/settings/`
    *   `features/about/`
3.  **Crucial:** Create the `AndroidManifest.xml` and `Info.plist` configurations required specifically for `just_audio_background` (service declaration and background modes).

### Step 2: Data Models & Service Locator
**Prompt for AI:**
1.  Create a `Song` model in `lib/models/song_model.dart`. It should contain: `id`, `title`, `reference` (subtitle), `url` (Cloudflare R2 link), and `artUri` (optional).
2.  Create a `ApiService` in `lib/core/services/api_service.dart`.
    *   For now, hardcode a list of 20 dummy songs pointing to valid public MP3 URLs (you can use test URLs or placeholders).
    *   The structure should simulate fetching from a remote source.
3.  Create a `lib/core/service_locator.dart` file. Use `get_it` to register `ApiService` as a lazy singleton.
4.  Initialize `setupLocator()` in `main.dart`.

### Step 3: Theme & User Settings Service
**Prompt for AI:**
1.  Create a `SettingsService` in `lib/core/services/settings_service.dart`.
    *   Use `SharedPreferences`.
    *   Keys: `theme_mode` (system, light, dark).
2.  Create an `AppState` class in `lib/core/app_state.dart`.
    *   It should hold a `ValueNotifier<ThemeMode>` currentTheme.
    *   It should load the preference from `SettingsService` on init.
3.  Register `SettingsService` and `AppState` in `get_it`.
4.  Update `main.dart` to use `ValueListenableBuilder` on the `AppState.currentTheme` to switch the `MaterialApp` theme dynamically.

### Step 4: Audio Logic (The Backend of the Frontend)
**Prompt for AI:**
1.  Create an `AudioManager` in `lib/core/services/audio_manager.dart`.
    *   Register it as a singleton in `get_it`.
    *   Initialize `AudioPlayer` from `just_audio`.
    *   Implement a method `initSongs(List<Song> songs)` that converts your models into a `ConcatenatingAudioSource` (using `AudioSource.uri` with `MediaItem` tags for the notification bar).
    *   Expose streams or ValueNotifiers for: `currentSongNotifier`, `isFirstSongNotifier`, `isLastSongNotifier`, `playButtonNotifier` (playing/paused/loading).
    *   Implement methods: `play`, `pause`, `seek`, `next`, `previous`, `setLoopMode` (off, one, all).
    *   Ensure `just_audio_background` is initialized in the `main` function before `runApp`.

### Step 5: Home Screen Architecture (Logic Layer)
**Prompt for AI:**
1.  Create `lib/features/home/home_manager.dart`.
    *   It should depend on `ApiService` and `AudioManager` (via `GetIt`).
    *   It should expose a `ValueNotifier<List<Song>>` for the UI list.
    *   It should expose a `ValueNotifier<ProgressBarState>` (create this simple class to hold current, buffered, and total duration).
    *   In the constructor, listen to the `AudioManager` position/buffered/duration streams and update the `ProgressBarState`.
    *   Add a method `loadSongs()` that fetches from API and sends to `AudioManager`.

### Step 6: Home Screen UI (Visual Layer)
**Prompt for AI:**
1.  Create `lib/features/home/home_screen.dart`.
    *   **Layout:** Use a `Column`. Top 30% is the Player, Bottom 70% is the List.
    *   **Player Section:**
        *   Display current song Title and Reference.
        *   Use `ProgressBar` widget from `audio_video_progress_bar`. Connect it to the manager's progress notifier.
        *   Row of controls: Repeat Mode Button, Previous, Play/Pause, Next.
    *   **List Section:**
        *   `ListView.builder` displaying the 20 songs.
        *   Use `ValueListenableBuilder` to listen to the song list.
        *   Each item: `ListTile` with Title, Reference.
        *   Trailing icon: A generic "More" menu (three dots) for now.
    *   **Interaction:** Tapping a song in the list should tell `AudioManager` to seek to that index and play.

### Step 7: Download & Share Features
**Prompt for AI:**
1.  Update `HomeManager`:
    *   Add a method `downloadSong(Song song)`.
    *   Use `http` to get bytes, `path_provider` to find the documents directory, and write the file.
    *   Add a method `shareSong(Song song)`. Use `share_plus` to share the text: "Listen to [Title] at [URL]".
2.  Update `HomeScreen` List Item:
    *   Change the trailing "More" icon to a `PopupMenuButton`.
    *   Options: "Download MP3", "Share".
    *   Connect these options to the `HomeManager` methods.

### Step 8: Settings & About Pages
**Prompt for AI:**
1.  Create `lib/features/settings/settings_screen.dart`.
    *   UI: A list of Radio Tiles or a Dropdown to select Theme (System, Light, Dark).
    *   Logic: specific `SettingsManager` is not strictly necessary here if it's simple; you can call `GetIt.I<AppState>().setTheme(...)` directly.
2.  Create `lib/features/about/about_screen.dart`.
    *   Simple text explaining the app version and purpose.
3.  Add navigation icons (Settings/Info) to the `AppBar` of the `HomeScreen`.

### Step 9: Final Polish
**Prompt for AI:**
1.  Review the `just_audio_background` notification setup. Ensure the `MediaItem` in `AudioManager` is correctly populated so the lock screen shows the Song Title and Reference.
2.  Ensure that `main.dart` initializes everything in the correct order (WidgetsFlutterBinding, AudioBackground, Locator).
3.  Verify that the "Repeat" button cycles through Off -> One -> All and updates the UI icon accordingly.