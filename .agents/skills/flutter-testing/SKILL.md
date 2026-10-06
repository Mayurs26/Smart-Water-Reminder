---
name: flutter-testing
description: >-
  Use when running, writing, or fixing tests in the Smart Water Reminder app.
  Covers flutter analyze, flutter test, the existing test file, testability patterns
  (injectable durations for SplashScreen), and how to add new tests.
---

# Flutter Testing — Smart Water Reminder

## Verification commands (run in this order, always)

```powershell
# In: c:\Users\mayur\Desktop\smart_water_reminder

flutter analyze lib/       # Must exit 0 and print "No issues found!"
flutter test               # Must print "+N: All tests passed!"
```

> **Windows note**: `flutter analyze` exits code 1 even for `info`-level issues.
> Check the **output text** — if it says "No issues found!" you're clean.
> If it says "N issues found" with real errors/warnings, fix them.

## Existing tests

- **`test/widget_test.dart`** — single test: `'Splash shows logo and app name, then navigates to next screen'`
  - Uses `SplashScreen` with all durations set to `Duration.zero` (injectable overrides).
  - `tester.pumpAndSettle(const Duration(milliseconds: 100))` drives everything to completion.
  - Asserts: `AppLogo` present initially, `Text('Home ready')` present after navigation, `AppLogo` gone.

## SplashScreen testability pattern

`SplashScreen` accepts optional duration parameters so tests use zero delays:

```dart
SplashScreen(
  next: const Scaffold(body: Text('Home ready')),
  introDuration: Duration.zero,
  exitDuration: Duration.zero,
  holdDuration: Duration.zero,
  transitionDuration: Duration.zero,
  startDelay: Duration.zero,
)
```
Production call: `const SplashScreen(next: AppEntryPoint())` — all defaults apply.

## Adding new widget tests

1. Create `test/<feature>_test.dart`.
2. Wrap widget under test in `MaterialApp` (minimum).
3. For Provider-dependent widgets, wrap in `MultiProvider` with mock/real providers.
4. Use `tester.pump()` for one frame, `tester.pumpAndSettle()` for animations.
5. **Never** use `await Future<void>.delayed(...)` in tests — it hangs under fake-async.
6. For `Timer`-based widgets (`_SmartReminderCard` has a 1s ticker): call `tester.pump(const Duration(seconds: 1))` to advance fake time.

## Common lint fixes

| Lint | Fix |
|---|---|
| `unnecessary_underscores` | Replace `(_, __, ___)` with `(_, _, _)` |
| `deprecated_member_use` | Add `// ignore: deprecated_member_use` on the line |
| `use_build_context_synchronously` | Add `if (!mounted) return;` before async gap |

## Analysis options

`analysis_options.yaml` uses `package:flutter_lints/flutter.yaml`.  
Excluded from analysis: `build/**`, `android/**`, `ios/**`, `web/**`, `windows/**`, `macos/**`, `linux/**`.
