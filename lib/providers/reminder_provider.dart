import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/core/services/notification_service.dart';
import 'package:smart_water_reminder/core/services/smart_reminder_engine.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';

class ReminderProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();
  UserProvider? _userProvider;
  WaterProvider? _waterProvider;

  ReminderProvider(this._prefs);

  bool get remindersEnabled =>
      _prefs.getBool(AppConstants.keyRemindersEnabled) ?? true;

  int get reminderInterval =>
      _prefs.getInt(AppConstants.keyReminderInterval) ??
      AppConstants.defaultReminderInterval;

  String get reminderStartTime =>
      _prefs.getString(AppConstants.keyReminderStartTime) ??
      AppConstants.defaultReminderStartTime;

  String get reminderEndTime =>
      _prefs.getString(AppConstants.keyReminderEndTime) ??
      AppConstants.defaultReminderEndTime;

  void setDependencies(UserProvider userProvider, WaterProvider waterProvider) {
    _userProvider = userProvider;
    _waterProvider = waterProvider;
  }

  Future<void> initialize() async {
    await _notificationService.initialize();
    final hasPermission = await _notificationService.requestPermissions();
    if (!hasPermission && remindersEnabled) {
      await setRemindersEnabled(false);
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyRemindersEnabled, enabled);
    if (enabled) {
      await _scheduleNextSmartReminder();
    } else {
      await _notificationService.cancelAllReminders();
    }
    notifyListeners();
  }

  Future<void> setReminderInterval(int interval) async {
    await _prefs.setInt(AppConstants.keyReminderInterval, interval);
    if (remindersEnabled) {
      await _scheduleNextSmartReminder();
    }
    notifyListeners();
  }

  Future<void> setReminderStartTime(String time) async {
    await _prefs.setString(AppConstants.keyReminderStartTime, time);
    if (remindersEnabled) {
      await _scheduleNextSmartReminder();
    }
    notifyListeners();
  }

  Future<void> setReminderEndTime(String time) async {
    await _prefs.setString(AppConstants.keyReminderEndTime, time);
    if (remindersEnabled) {
      await _scheduleNextSmartReminder();
    }
    notifyListeners();
  }

  /// Called after every water intake to reschedule the next smart reminder
  /// with the dynamically calculated recommended amount.
  Future<void> onWaterIntakeAdded() async {
    if (!remindersEnabled) return;
    await _scheduleNextSmartReminder();
  }

  Future<void> checkAndRescheduleIfGoalMet() async {
    final userSettings = _userProvider?.userSettings;
    final consumed = _waterProvider?.totalConsumed ?? 0;

    if (userSettings == null) return;

    if (consumed >= userSettings.dailyGoal) {
      // Goal met — cancel all reminders for today.
      await _notificationService.cancelAllReminders();
    } else {
      await _scheduleNextSmartReminder();
    }
  }

  Future<void> rescheduleReminders() async {
    if (remindersEnabled) {
      await _scheduleNextSmartReminder();
    }
  }

  // ─── internal ─────────────────────────────────────────────────────────────

  Future<void> _scheduleNextSmartReminder() async {
    final userSettings = _userProvider?.userSettings;
    final waterProv = _waterProvider;
    if (userSettings == null || waterProv == null) return;

    final dailyGoal = userSettings.dailyGoal;
    final consumed = waterProv.totalConsumed;
    final todayIntakes = waterProv.todayIntakes;
    final interval = reminderInterval;
    final endTime = reminderEndTime;

    // Nothing to remind if goal already met.
    if (consumed >= dailyGoal) {
      await _notificationService.cancelAllReminders();
      return;
    }

    final nextTime = SmartReminderEngine.nextReminderTime(
      todayIntakes: todayIntakes,
      intervalHours: interval,
      endTimeStr: endTime,
    );

    final recommended = SmartReminderEngine.recommendedAmount(
      dailyGoal: dailyGoal,
      consumed: consumed,
      intervalHours: interval,
      endTimeStr: endTime,
    );

    await _notificationService.scheduleSmartReminder(
      scheduledTime: nextTime,
      recommendedAmount: recommended,
    );
  }
}