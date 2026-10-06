import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';

/// Singleton notification service.
///
/// ## Timezone strategy
/// Dart's [DateTime] always stores time as microseconds since the Unix epoch
/// (UTC-based), regardless of whether it is local or UTC.
/// [tz.TZDateTime.fromMillisecondsSinceEpoch] preserves that absolute epoch
/// value, so scheduling is timezone-safe without needing flutter_timezone.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ──────────────────────────────────────────────────────────────────────────
  //  Initialization
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Load timezone database. Do NOT call setLocalLocation with tz.local.name
    // because tz.local.name is "UTC" before being set — that bug caused
    // notifications to fire 5.5h late on IST devices.
    tz_data.initializeTimeZones();
    debugPrint('[NotifService] Timezone database loaded. tz.local = ${tz.local.name}');

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
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );
    debugPrint('[NotifService] Plugin initialized.');

    await _createNotificationChannel();
    debugPrint('[NotifService] Channel created: ${AppConstants.notificationChannelId}');

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
      sound: null, // default system sound
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      debugPrint('[NotifService] Notification permission: already granted.');
      return true;
    }
    final status = await Permission.notification.request();
    debugPrint('[NotifService] Notification permission requested: ${status.name}');
    return status.isGranted;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Smart scheduling — primary path
  // ──────────────────────────────────────────────────────────────────────────

  /// Cancel all pending notifications, then schedule exactly ONE at
  /// [scheduledTime] (a local [DateTime]) with [recommendedAmount] ml.
  ///
  /// Uses [AndroidScheduleMode.alarmClock] which:
  ///   - does NOT require SCHEDULE_EXACT_ALARM permission
  ///   - fires even in doze/idle mode
  ///   - fires exactly on time in background and when app is terminated
  Future<void> scheduleSmartReminder({
    required DateTime scheduledTime,
    required int recommendedAmount,
  }) async {
    await cancelAllReminders();
    debugPrint('[NotifService] cancelAllReminders() done before scheduling.');

    final now = DateTime.now();
    final delayMs = scheduledTime.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    debugPrint('[NotifService] --- scheduleSmartReminder ---');
    debugPrint('[NotifService] Now (local):       $now');
    debugPrint('[NotifService] Scheduled (local): $scheduledTime');
    debugPrint('[NotifService] Delay:             ${delayMs}ms  (${delayMs ~/ 1000}s)');

    if (delayMs <= 0) {
      debugPrint('[NotifService] ⚠ Scheduled time is in the past — skipping.');
      return;
    }

    await _scheduleNotification(
      id: AppConstants.notificationId,
      title: '💧 Time to Drink Water',
      body: "It's time to drink $recommendedAmount ml of water.",
      scheduledTime: scheduledTime,
      payload: 'drink_$recommendedAmount',
    );

    // Verify it landed in the pending list.
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('[NotifService] Pending after schedule: ${pending.length}');
    for (final p in pending) {
      debugPrint('[NotifService]   id=${p.id}  title="${p.title}"  body="${p.body}"');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Legacy full-day scheduling (app-start / setting change without intake)
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
    // KEY FIX: use millisecondsSinceEpoch to create the TZDateTime.
    // Dart's DateTime.millisecondsSinceEpoch is always UTC-based (absolute),
    // so this is timezone-safe — no tz.local required.
    final tz.TZDateTime tzTime = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      scheduledTime.millisecondsSinceEpoch,
    );

    debugPrint('[NotifService] _scheduleNotification id=$id');
    debugPrint('[NotifService]   tzTime (UTC): $tzTime');
    debugPrint('[NotifService]   scheduledTime (local): $scheduledTime');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: null, // default system sound
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
      // alarmClock mode: fires exactly on time, no SCHEDULE_EXACT_ALARM needed.
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('[NotifService] ✓ zonedSchedule succeeded for id=$id');
    } catch (e, st) {
      debugPrint('[NotifService] ✗ zonedSchedule FAILED: $e');
      debugPrint('$st');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Tap handler
  // ──────────────────────────────────────────────────────────────────────────

  static void _onNotificationTapped(NotificationResponse response) {
    // Bring app to foreground — payload: 'drink_<amount>'
    debugPrint('[NotifService] Notification tapped. payload=${response.payload}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Cancel / query
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> cancelAllReminders() async {
    debugPrint('[NotifService] cancelAllReminders()');
    await _notifications.cancelAll();
  }

  Future<void> cancelReminder(int id) async {
    debugPrint('[NotifService] cancelReminder(id=$id)');
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