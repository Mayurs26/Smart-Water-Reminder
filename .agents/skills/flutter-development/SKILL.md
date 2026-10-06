---
name: flutter-development
description: >-
  Use when implementing new features, modifying screens, providers, models,
  repositories, or services in the Smart Water Reminder Flutter app.
  Covers architecture conventions, where code belongs, state management patterns,
  widget/theme rules, and navigation.
---

# Flutter Development — Smart Water Reminder

## Architecture at a glance

| Layer | Location | Rule |
|---|---|---|
| Screens / UI | `lib/features/<feature>/screens/` | StatefulWidget or StatelessWidget. No business logic. |
| Feature widgets | `lib/features/<feature>/widgets/` | Reusable within the feature. |
| Shared widgets | `lib/core/widgets/` | Reusable across features (`AppLogo`). |
| Business logic | `lib/core/services/` | Pure Dart, no Flutter Widget imports. |
| State | `lib/providers/` | `ChangeNotifier`. Registered in `main.dart`. |
| Data access | `lib/data/repositories/` | Wraps `DatabaseService`. Providers call repositories. |
| DB layer | `lib/data/database/database_service.dart` | Singleton SQLite. Never call directly from UI. |
| Models | `lib/data/models/` | Plain Dart. `toMap()` / `fromMap()` / `copyWith()`. |
| Constants | `lib/core/constants/app_constants.dart` | ALL keys and defaults live here. |
| Theme | `lib/core/theme/app_theme.dart` | ALL colors. Use `AppTheme.*` or `theme.colorScheme.*`. |

## Adding a new feature

1. Create `lib/features/<name>/screens/<name>_screen.dart`.
2. If it needs state → add a method to an **existing** provider, or create a new provider in `lib/providers/` and register it in `main.dart` `MultiProvider`.
3. If it needs DB access → add a method to an existing repository (or create a new one that only calls `DatabaseService`).
4. If it needs shared computation → add a static class to `lib/core/services/`.
5. Navigate to it with `MaterialPageRoute` from `HomeScreen` or add it to the bottom nav in `MainNavigationScreen`.

## State management patterns

```dart
// Read without subscribing (inside callbacks / initState via addPostFrameCallback)
context.read<WaterProvider>().addWaterIntake(amount);

// Subscribe and rebuild
Consumer<WaterProvider>(builder: (ctx, wp, _) { ... })
// or
context.watch<WaterProvider>().totalConsumed

// Cross-provider dependency (see main.dart)
ChangeNotifierProxyProvider2<UserProvider, WaterProvider, ReminderProvider>(
  create: (_) => ReminderProvider(prefs)..initialize(),
  update: (_, u, w, r) { r!.setDependencies(u, w); return r; },
)
```

## Theme / design tokens

```dart
// Always use theme or AppTheme — never Color(0x...)  inline
theme.colorScheme.primary        // accent color (sky-blue)
theme.colorScheme.surface        // card background
theme.colorScheme.onSurface      // primary text
AppTheme.success                 // green
AppTheme.warning                 // amber
// Dark: deep navy bg (0xFF04101C), aqua/teal accents
// Light: sky-white bg (0xFFF0F9FF), sky-blue accents
```

## Onboarding gate

`UserSettings.isOnboarded` requires `name != null && weight != null && gender != null`.
`AppEntryPoint` routes to `OnboardingScreen` when false — never bypass this.

## Daily goal formula

`dailyGoal = weight * 35` ml (set during onboarding in `WaterGoalScreen`).
Default: 2500 ml for 55 kg.

## Navigation

- 4-tab bottom nav: Home · Analytics · Achievements · Settings.
- Push modal routes with `Navigator.push(context, MaterialPageRoute(...))`.
- No named routes. No `GoRouter`.
- `SplashScreen(next: AppEntryPoint())` is the MaterialApp home.

## Midnight reset

`WaterProvider` arms a `dart:async Timer` at midnight to roll over the day. No app restart needed.

## Key file sizes (for context budget planning)

| File | Lines |
|---|---|
| `home_screen.dart` | ~1000 |
| `notification_service.dart` | ~230 |
| `database_service.dart` | ~182 |
| `settings_screen.dart` | large |
| `reminder_provider.dart` | ~145 |
| `water_provider.dart` | ~190 |
