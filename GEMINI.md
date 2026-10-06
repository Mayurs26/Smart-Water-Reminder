# Smart Water Reminder — Project Rules

## Stack
- **Flutter 3.47.2 / Dart 3.13.2** — SDK constraint `^3.13.2`
- **Android only** (iOS/web/linux/macos/windows scaffolded but unused)
- **State management**: `provider ^6.1.2` — `ChangeNotifier` + `ChangeNotifierProxyProvider2`
- **Local DB**: `sqflite ^2.3.3` — singleton `DatabaseService`, schema v3
- **Light persistence**: `shared_preferences ^2.3.2` — reminder settings, theme mode
- **Notifications**: `flutter_local_notifications ^18.0.1` + `timezone ^0.9.4` + `permission_handler ^11.3.1`
- **Charts**: `fl_chart ^0.70.2`
- **Date formatting**: `intl ^0.19.0`

## Architecture — Layered Feature-First

```
lib/
  main.dart                     ← Provider tree, AppEntryPoint, MainNavigationScreen
  core/
    constants/app_constants.dart ← ALL string keys, default values, channel IDs
    services/
      notification_service.dart  ← Singleton. ONLY place notifications are scheduled.
      smart_reminder_engine.dart ← Pure computation. No Flutter deps. Engine for next-reminder logic.
    theme/app_theme.dart         ← All colors, ThemeData. Do NOT define colors elsewhere.
    utils/date_utils.dart        ← AppDateUtils static helpers
    widgets/app_logo.dart        ← AppLogo reusable widget
  data/
    database/database_service.dart ← Singleton SQLite. Schema v3.
    models/
      user_settings.dart         ← UserSettings, ThemeModeType
      water_intake.dart          ← WaterIntake
    repositories/
      user_repository.dart       ← UserRepository (wraps DatabaseService)
      water_repository.dart      ← WaterRepository (wraps DatabaseService)
  providers/
    user_provider.dart           ← UserProvider (UserSettings CRUD + onboarding check)
    water_provider.dart          ← WaterProvider (today's intakes, totals, midnight reset)
    reminder_provider.dart       ← ReminderProvider (SharedPrefs settings + schedules notifications)
    theme_provider.dart          ← ThemeProvider (SharedPrefs theme mode)
  features/
    analytics/                   ← AnalyticsScreen, widgets, models
    gamification/                ← GamificationProvider (SharedPrefs), screens, widgets
    history/                     ← HistoryScreen, HydrationTimelineScreen, widgets
    home/                        ← HomeScreen, QuickAddButtons, StatsRow, CustomAmountDialog
    onboarding/                  ← OnboardingScreen + sub-screens + OnboardingData model
    presets/                     ← BottlePreset model (unused UI — feature-in-progress)
    reminders/                   ← RemindersScreen
    settings/                    ← SettingsScreen
    splash/                      ← SplashScreen (accepts injectable duration overrides for testing)
test/
  widget_test.dart               ← Single widget test (SplashScreen navigation)
```

## Development Rules

### Before modifying
1. Search before reading — use `Select-String` / grep to find the relevant class/method first.
2. Only open files you need to change or understand.
3. Do NOT read `build/`, `.dart_tool/`, `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` unless the task explicitly requires it.
4. Do NOT re-read files you already read in the same session.

### Architecture rules
- **New features** → `lib/features/<feature_name>/` (screens/, widgets/, models/ sub-dirs as needed).
- **Shared business logic** → `lib/core/services/` (pure Dart classes, no Flutter widget deps).
- **State** → `lib/providers/` only. Never put `ChangeNotifier` inside a feature folder.
- **DB access** → only through `WaterRepository` or `UserRepository`. Never call `DatabaseService` directly from providers or UI.
- **Notification scheduling** → only through `NotificationService`. `ReminderProvider` is the sole caller from the app layer.
- **Colors / theme tokens** → only from `AppTheme`. Never hardcode colors in widget files.
- **String keys / constants** → only from `AppConstants`. Never hardcode string keys.
- **Date formatting** → only from `AppDateUtils`.

### Do NOT
- Duplicate `NotificationService` or create a second notification scheduler.
- Create a second database service or open SQLite directly.
- Create a second `WaterProvider`, `UserProvider`, or `ReminderProvider`.
- Bypass the repository layer.
- Hardcode colors — use `AppTheme.*` or `theme.colorScheme.*`.
- Hardcode SharedPreferences keys — use `AppConstants.key*`.
- Add new `pubspec.yaml` dependencies without being asked.
- Modify `.github/workflows/` unless explicitly requested.
- Upgrade SDK/dependency versions unless explicitly required.
- Touch platform files (`android/`, `ios/`) unless the task requires it.

### State management conventions
- Providers are registered in `main.dart` `MultiProvider`.
- Cross-provider dependency: use `ChangeNotifierProxyProvider2` (see `ReminderProvider`).
- Inter-provider callbacks: use `setOnWaterChanged()` callback wired in `AppEntryPoint.build()`.
- Read without rebuilding: `context.read<T>()`. Rebuild on change: `context.watch<T>()` or `Consumer<T>`.
- In `initState`: use `WidgetsBinding.instance.addPostFrameCallback` to access providers.

### Navigation
- Bottom nav (4 tabs): Home, Analytics, Achievements, Settings — managed by `MainNavigationScreen`.
- Modal routes: `Navigator.push(context, MaterialPageRoute(...))` — used for History and Reminders.
- `EndDrawer` provides secondary navigation to History, Reminders, Settings.
- No named routes. No `GoRouter`.

### Database schema (v3)
- `user_settings`: id, name, age, weight, gender, daily_goal, wake_up_time, sleep_time, reminder_interval, reminders_enabled, reminder_start_time, reminder_end_time, activity_level, theme_mode
- `water_intake`: id, amount, timestamp (milliseconds), date (yyyy-MM-dd), indexed on `date`
- Upgrades via `_onUpgrade` in `DatabaseService`. Bump version + add migration before any schema change.

### Onboarding gate
- `UserSettings.isOnboarded` = `name != null && weight != null && gender != null`.
- `AppEntryPoint` routes to `OnboardingScreen` when `!userProvider.isOnboarded`.

### Verification — always run in this order
```
flutter analyze lib/
flutter test
```
Fix all issues before considering a task done. Zero warnings required (`flutter analyze` must exit 0).

## Safe-to-ignore directories
`build/`, `.dart_tool/`, `.idea/`, `.gradle/`, `android/.kotlin/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`, platform-generated `GeneratedPluginRegistrant.*`, `pubspec.lock` (read-only reference).
