import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/core/services/notification_service.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';

class ReminderProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();
  UserProvider? _userProvider;
  WaterProvider? _waterProvider;

  ReminderProvider(this._prefs);

  bool get remindersEnabled => _prefs.getBool(AppConstants.keyRemindersEnabled) ?? true;
  int get reminderInterval => _prefs.getInt(AppConstants.keyReminderInterval) ?? AppConstants.defaultReminderInterval;
  String get reminderStartTime => _prefs.getString(AppConstants.keyReminderStartTime) ?? AppConstants.defaultReminderStartTime;
  String get reminderEndTime => _prefs.getString(AppConstants.keyReminderEndTime) ?? AppConstants.defaultReminderEndTime;

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
      await _scheduleReminders();
    } else {
      await _notificationService.cancelAllReminders();
    }
    notifyListeners();
  }

  Future<void> setReminderInterval(int interval) async {
    await _prefs.setInt(AppConstants.keyReminderInterval, interval);
    if (remindersEnabled) {
      await _scheduleReminders();
    }
    notifyListeners();
  }

  Future<void> setReminderStartTime(String time) async {
    await _prefs.setString(AppConstants.keyReminderStartTime, time);
    if (remindersEnabled) {
      await _scheduleReminders();
    }
    notifyListeners();
  }

  Future<void> setReminderEndTime(String time) async {
    await _prefs.setString(AppConstants.keyReminderEndTime, time);
    if (remindersEnabled) {
      await _scheduleReminders();
    }
    notifyListeners();
  }

  Future<void> _scheduleReminders() async {
    final userSettings = _userProvider?.userSettings;
    if (userSettings != null) {
      await _notificationService.scheduleDailyReminders(userSettings);
    }
  }

  Future<void> checkAndRescheduleIfGoalMet() async {
    final userSettings = _userProvider?.userSettings;
    final consumed = _waterProvider?.totalConsumed ?? 0;
    if (userSettings != null) {
      await _notificationService.checkAndRescheduleIfGoalMet(userSettings, consumed);
    }
  }

  Future<void> rescheduleReminders() async {
    if (remindersEnabled) {
      await _scheduleReminders();
    }
  }
}