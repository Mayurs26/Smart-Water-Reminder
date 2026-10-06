import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TOP-LEVEL background notification handler.
//
//  MUST be a top-level function (not a class method, not a closure).
//  MUST be annotated @pragma('vm:entry-point') so the Dart VM can locate it
//  from the background isolate that flutter_local_notifications creates when
//  the scheduled alarm fires while the app is backgrounded.
//
//  Crash Bug #3 fix: previously this was a static class method without @pragma.
//  The background isolate's VM could not find the function → crash on alarm fire.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Background isolate — ONLY safe operations here.
  // No Provider, no BuildContext, no SQLite, no UI widgets.
  debugPrint('[NotifBg] id=${response.id}  payload=${response.payload}');
}

// Foreground handler (app is visible when notification is tapped).
void _onForegroundNotificationResponse(NotificationResponse response) {
  debugPrint('[NotifFg] id=${response.id}  payload=${response.payload}');
}

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationService — singleton
//
//  Timezone strategy
//  -----------------
//  Dart's DateTime.millisecondsSinceEpoch is always the absolute UTC epoch
//  value regardless of whether the DateTime is local or UTC.
//  tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, ms) preserves that
//  absolute value → scheduling is timezone-safe, no flutter_timezone needed.
//
//  Scheduling mode
//  ---------------
//  exactAllowWhileIdle  — uses AlarmManager.setExactAndAllowWhileIdle().
//    • Fires even in doze/idle mode.
//    • Does NOT trigger MIUI's alarm-clock system (setAlarmClock did → crash).
//    • Requires SCHEDULE_EXACT_ALARM permission on Android 12+ (API 31).
//      We request it at initialization. If denied, scheduling catches the
//      PlatformException and logs it — no crash, just no notification until
//      the user grants "Alarms & Reminders" in device settings.
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ──────────────────────────────────────────────────────────────────────────
  //  Initialize
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Load timezone database. Do NOT call setLocalLocation(tz.local.name):
    // tz.local.name is "UTC" by default before any location is set.
    // Reading it and writing it back cemented UTC as the device timezone,
    // causing notifications to fire ~5.5h late on IST devices (Bug #tz).
    tz_data.initializeTimeZones();
    debugPrint('[NotifSvc] tz database loaded. tz.local=${tz.local.name}');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      // Bug #3 fix: both handlers are now top-level functions.
      // _onBackgroundNotificationResponse has @pragma('vm:entry-point').
      onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );
    debugPrint('[NotifSvc] plugin initialized');

    await _createNotificationChannel();
    debugPrint('[NotifSvc] channel "${AppConstants.notificationChannelId}" created');

    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      // null = default system sound for the channel
      sound: null,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Permission helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Requests POST_NOTIFICATIONS (Android 13+) and SCHEDULE_EXACT_ALARM
  /// (Android 12+). Returns true if POST_NOTIFICATIONS is granted.
  Future<bool> requestPermissions() async {
    // ── POST_NOTIFICATIONS ──────────────────────────────────────────────────
    bool notifGranted = await Permission.notification.isGranted;
    if (!notifGranted) {
      final status = await Permission.notification.request();
      notifGranted = status.isGranted;
      debugPrint('[NotifSvc] POST_NOTIFICATIONS → ${status.name}');
    } else {
      debugPrint('[NotifSvc] POST_NOTIFICATIONS → already granted');
    }

    // ── SCHEDULE_EXACT_ALARM ────────────────────────────────────────────────
    // Android 12+ (API 31): required for exactAllowWhileIdle scheduling.
    // permission_handler opens "Alarms & Reminders" settings page for Android 12+.
    // On older Android, this permission is auto-granted.
    if (Platform.isAndroid) {
      final exactStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('[NotifSvc] SCHEDULE_EXACT_ALARM → ${exactStatus.name}');
      if (!exactStatus.isGranted) {
        // This opens Settings → Apps → [App] → Alarms & Reminders
        final result = await Permission.scheduleExactAlarm.request();
        debugPrint('[NotifSvc] SCHEDULE_EXACT_ALARM after request → ${result.name}');
      }
    }

    return notifGranted;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Smart scheduling — primary path
  // ──────────────────────────────────────────────────────────────────────────

  /// Cancels all pending notifications and schedules exactly ONE at
  /// [scheduledTime] (a local [DateTime]).
  Future<void> scheduleSmartReminder({
    required DateTime scheduledTime,
    required int recommendedAmount,
  }) async {
    await cancelAllReminders();

    final now = DateTime.now();
    final delayMs = scheduledTime.millisecondsSinceEpoch - now.millisecondsSinceEpoch;

    debugPrint('[NotifSvc] ── scheduleSmartReminder ──');
    debugPrint('[NotifSvc] Now (local):       $now');
    debugPrint('[NotifSvc] Scheduled (local): $scheduledTime');
    debugPrint('[NotifSvc] Delay:             ${(delayMs / 1000).toStringAsFixed(1)}s');

    if (delayMs <= 0) {
      debugPrint('[NotifSvc] ⚠ Scheduled time is in the past — skipped.');
      return;
    }

    await _scheduleNotification(
      id: AppConstants.notificationId,
      title: '💧 Time to Drink Water',
      body: "It's time to drink $recommendedAmount ml of water.",
      scheduledTime: scheduledTime,
      payload: 'drink_$recommendedAmount',
    );

    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('[NotifSvc] Pending count after schedule: ${pending.length}');
    for (final p in pending) {
      debugPrint('[NotifSvc]   → id=${p.id}  "${p.title}"');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Legacy full-day scheduling (app-start / setting change, no intake data)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> scheduleDailyReminders(UserSettings settings) async {
    if (!settings.remindersEnabled) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final wakeTime = _parseTime(settings.reminderStartTime);
    final sleepTime = _parseTime(settings.reminderEndTime);

    DateTime startTime = today.add(
        Duration(hours: wakeTime.hour, minutes: wakeTime.minute));
    DateTime endTime = today.add(
        Duration(hours: sleepTime.hour, minutes: sleepTime.minute));

    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }
    if (endTime.isBefore(now)) {
      startTime = startTime.add(const Duration(days: 1));
      endTime = endTime.add(const Duration(days: 1));
    }

    final intervalMinutes = settings.reminderInterval;
    DateTime currentTime = startTime;
    int notifId = AppConstants.notificationId;

    while (currentTime.isBefore(endTime)) {
      if (currentTime.isAfter(now)) {
        await _scheduleNotification(
          id: notifId++,
          title: '💧 Time to Drink Water',
          body: "It's time to drink water — stay on track with your daily goal.",
          scheduledTime: currentTime,
          payload: 'drink_reminder',
        );
      }
      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Core scheduling
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    // Timezone-safe: millisecondsSinceEpoch is always the absolute UTC epoch
    // value, so using tz.UTC here preserves the exact moment regardless of
    // what tz.local is set to on the device.
    final tz.TZDateTime tzTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      scheduledTime.millisecondsSinceEpoch,
    );

    debugPrint('[NotifSvc] _scheduleNotification id=$id');
    debugPrint('[NotifSvc]   local  → $scheduledTime');
    debugPrint('[NotifSvc]   tzTime → $tzTime');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      // Inherit sound from channel (null = default system notification sound)
      sound: null,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Crash Bug #2 fix: switched from alarmClock to exactAllowWhileIdle.
      //
      // alarmClock (AlarmManager.setAlarmClock) was causing crashes on MIUI
      // because MIUI intercepts alarm-clock alarms and runs its own alarm
      // overlay/service, which crashed the app process.
      //
      // exactAllowWhileIdle (AlarmManager.setExactAndAllowWhileIdle) fires on
      // time even in doze mode WITHOUT triggering MIUI's alarm clock system.
      // It requires SCHEDULE_EXACT_ALARM permission (Android 12+), which we
      // request in requestPermissions(). If denied, the PlatformException is
      // caught below — scheduling fails gracefully (no crash, just no alarm).
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[NotifSvc] ✓ Scheduled id=$id');
    } on PlatformException catch (e) {
      // exact_alarms_not_permitted: user hasn't enabled "Alarms & Reminders"
      // in Settings → Apps → smart_water_reminder. No crash — just log.
      debugPrint('[NotifSvc] ✗ Schedule failed (${e.code}): ${e.message}');
      debugPrint('[NotifSvc]   → Guide user to Settings → Apps → Alarms & Reminders');
    } catch (e, st) {
      debugPrint('[NotifSvc] ✗ Unexpected schedule error: $e\n$st');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Cancel / query
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> cancelAllReminders() async {
    debugPrint('[NotifSvc] cancelAllReminders()');
    await _notifications.cancelAll();
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────────────────

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}