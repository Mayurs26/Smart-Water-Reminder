import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      'ic_launcher',
    );

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
      onDidReceiveNotificationResponse: _onNotificationAction,
      onDidReceiveBackgroundNotificationResponse: _onNotificationAction,
    );

    await _createNotificationChannel();
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
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleDailyReminders(UserSettings settings) async {
    if (!settings.remindersEnabled) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final wakeTime = _parseTime(settings.wakeUpTime);
    final sleepTime = _parseTime(settings.sleepTime);

    DateTime startTime = today.add(Duration(hours: wakeTime.hour, minutes: wakeTime.minute));
    DateTime endTime = today.add(Duration(hours: sleepTime.hour, minutes: sleepTime.minute));

    if (endTime.isBefore(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    if (endTime.isBefore(now)) {
      startTime = startTime.add(const Duration(days: 1));
      endTime = endTime.add(const Duration(days: 1));
    }

    final intervalMinutes = settings.reminderInterval * 60;
    DateTime currentTime = startTime;

    int notificationId = AppConstants.notificationId;

    while (currentTime.isBefore(endTime)) {
      if (currentTime.isAfter(now)) {
        await _scheduleNotification(
          id: notificationId++,
          title: '💧 Time to drink water!',
          body: 'Stay hydrated and keep your daily goal on track.',
          scheduledTime: currentTime,
          payload: 'drink_250',
        );
      }
      currentTime = currentTime.add(Duration(minutes: intervalMinutes));
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
  }) async {
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  void _onNotificationAction(NotificationResponse response) {
    final actionId = response.actionId;

    if (actionId == 'drink_250') {
      _handleDrinkAction(250);
    } else if (actionId == 'snooze_15') {
      _handleSnoozeAction();
    } else if (actionId == 'skip') {
      _handleSkipAction();
    }
  }

  void _handleDrinkAction(int amount) {
  }

  void _handleSnoozeAction() {
  }

  void _handleSkipAction() {
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> checkAndRescheduleIfGoalMet(UserSettings settings, int consumedToday) async {
    if (!settings.remindersEnabled) return;

    if (consumedToday >= settings.dailyGoal) {
      await cancelAllReminders();
    } else {
      final pending = await getPendingNotifications();
      if (pending.isEmpty) {
        await scheduleDailyReminders(settings);
      }
    }
  }
}