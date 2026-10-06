---
name: notification-development
description: >-
  Use when modifying, extending, or debugging notification scheduling in the
  Smart Water Reminder app. Covers the existing NotificationService, SmartReminderEngine,
  ReminderProvider, Android permissions/manifest requirements, and how to avoid
  duplicate scheduling.
---

# Notification Development — Smart Water Reminder

## Architecture

```
SmartReminderEngine          ← Pure computation. No Flutter deps. Call this to calculate.
      ↓ (results)
ReminderProvider             ← Owns settings (SharedPrefs). Calls NotificationService.
      ↓ (schedules)
NotificationService          ← Singleton. ONLY place that touches FlutterLocalNotificationsPlugin.
```

**Rule**: Never call `NotificationService` from UI or from `WaterProvider` directly.
Always go through `ReminderProvider`.

## NotificationService (`lib/core/services/notification_service.dart`)

Singleton (`factory` constructor). Key methods:

| Method | Purpose |
|---|---|
| `initialize()` | Init plugin + create Android channel. Called once in `ReminderProvider.initialize()`. |
| `requestPermissions()` | Uses `permission_handler`. Returns bool. |
| `scheduleDailyReminders(UserSettings)` | Legacy: schedules fixed-interval reminders for the full day. |
| `scheduleSmartReminder({DateTime, int})` | Smart: cancels all → schedules ONE next notification with dynamic recommended amount. |
| `cancelAllReminders()` | Cancels all pending notifications. |
| `checkAndRescheduleIfGoalMet(settings, consumed)` | Cancels if goal met, reschedules otherwise. |

**Notification channel**: ID = `water_reminders`, importance = `Importance.high`.
**Notification icon**: `ic_launcher` (Android mipmap). Do NOT reference drawable resources that don't exist.
**Base notification ID**: `AppConstants.notificationId` = 1001.

## SmartReminderEngine (`lib/core/services/smart_reminder_engine.dart`)

Pure static methods — call these to compute values, then pass results to `NotificationService`:

```dart
SmartReminderEngine.lastIntakeTime(todayIntakes)           // → DateTime?
SmartReminderEngine.nextReminderTime(intakes, hours, end)  // → DateTime
SmartReminderEngine.countdownMinutes(intakes, hours, end)  // → int
SmartReminderEngine.remainingSlots(hours, end)             // → int (≥1)
SmartReminderEngine.recommendedAmount(goal, consumed, hours, end) // → int (50–800 ml, rounded to 50)
```

Logic: `nextTime = lastIntake + intervalHours` (falls back to `now + interval`). Capped at `reminderEndTime`.
Recommended: `ceil(remaining ÷ remainingSlots)` rounded to nearest 50 ml.

## ReminderProvider (`lib/providers/reminder_provider.dart`)

Settings stored in `SharedPreferences`:
- `remindersEnabled` (bool) — key: `AppConstants.keyRemindersEnabled`
- `reminderInterval` (int, hours, default 2) — key: `AppConstants.keyReminderInterval`
- `reminderStartTime` (String "HH:mm", default "09:00") — key: `AppConstants.keyReminderStartTime`
- `reminderEndTime` (String "HH:mm", default "21:00") — key: `AppConstants.keyReminderEndTime`

Key method called after every water intake (wired in `main.dart`):
```dart
reminderProvider.onWaterIntakeAdded()        // → reschedules smart reminder
reminderProvider.checkAndRescheduleIfGoalMet() // → cancels if goal met
```

`setDependencies(UserProvider, WaterProvider)` is called by `ChangeNotifierProxyProvider2` on every update.

## Android requirements

`AndroidManifest.xml` does **not** currently declare notification or alarm permissions explicitly — these are handled by `permission_handler` at runtime. If adding `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`, add to the manifest and test on Android 12+.

`AndroidScheduleMode.exactAllowWhileIdle` is already set in `_scheduleNotification()`.

**Do NOT add** custom drawable resources for notification actions (e.g., `ic_drink`, `ic_snooze`) unless you add the actual `.png` files to `android/app/src/main/res/drawable/`.

## Avoiding duplicate scheduling

- `scheduleSmartReminder()` calls `cancelAllReminders()` before scheduling — always exactly one pending notification at a time.
- `scheduleDailyReminders()` also calls `cancelAllReminders()` first.
- Never call both `scheduleDailyReminders()` and `scheduleSmartReminder()` for the same event.

## Wiring new notification triggers

If a new screen/provider needs to reschedule reminders:
1. Call `context.read<ReminderProvider>().rescheduleReminders()` (already calls the smart scheduler).
2. Do NOT create a new `NotificationService` instance — it's a singleton with `factory` constructor.

## Timezone

`tz.initializeTimeZones()` is called in `NotificationService.initialize()`.
`tz.TZDateTime.from(scheduledTime, tz.local)` is used for all scheduled notifications.
