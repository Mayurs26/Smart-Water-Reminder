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

  /// Interval stored and returned in MINUTES.
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
    debugPrint('[ReminderProvider] initialize() called');
    await _notificationService.initialize();
    final hasPermission = await _notificationService.requestPermissions();
    debugPrint('[ReminderProvider] hasPermission=$hasPermission  remindersEnabled=$remindersEnabled');
    if (!hasPermission && remindersEnabled) {
      await setRemindersEnabled(false);
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    debugPrint('[ReminderProvider] setRemindersEnabled($enabled)');
    await _prefs.setBool(AppConstants.keyRemindersEnabled, enabled);
    if (enabled) {
      await _scheduleNextSmartReminder();
    } else {
      await _notificationService.cancelAllReminders();
    }
    notifyListeners();
  }

  /// [intervalMinutes] — interval in minutes (e.g. 1, 2, 5, 60, 120).
  Future<void> setReminderInterval(int intervalMinutes) async {
    debugPrint('[ReminderProvider] setReminderInterval($intervalMinutes min)');
    await _prefs.setInt(AppConstants.keyReminderInterval, intervalMinutes);
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

  /// Called after every water intake.
  ///
  /// Handles both cases in a SINGLE pass — no separate
  /// [checkAndRescheduleIfGoalMet] call is needed.
  ///
  /// BUG FIX: previously the caller (main.dart) called BOTH this method AND
  /// [checkAndRescheduleIfGoalMet], causing a cancel→reschedule→cancel race
  /// where [scheduleSmartReminder] (which cancels-all first) was invoked twice
  /// sequentially, potentially cancelling the just-scheduled notification.
  Future<void> onWaterIntakeAdded() async {
    if (!remindersEnabled) {
      debugPrint('[ReminderProvider] onWaterIntakeAdded: reminders disabled — skipping.');
      return;
    }
    debugPrint('[ReminderProvider] onWaterIntakeAdded()');
    await _scheduleNextSmartReminder();
  }

  /// Kept for backward compatibility — delegates to [_scheduleNextSmartReminder]
  /// which already handles goal-met cancellation internally.
  Future<void> checkAndRescheduleIfGoalMet() async {
    // This is now a no-op: _scheduleNextSmartReminder already cancels when
    // goal is met. The caller in main.dart has been updated to call only
    // onWaterIntakeAdded(), so this method is never called from the hot path.
    // Kept to avoid breaking any existing screen that might call it directly.
    debugPrint('[ReminderProvider] checkAndRescheduleIfGoalMet() — delegating.');
    if (!remindersEnabled) return;
    await _scheduleNextSmartReminder();
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
    if (userSettings == null || waterProv == null) {
      debugPrint('[ReminderProvider] _scheduleNextSmartReminder: deps not ready — skipping.');
      return;
    }

    final dailyGoal = userSettings.dailyGoal;
    final consumed = waterProv.totalConsumed;
    final todayIntakes = waterProv.todayIntakes;
    final intervalMins = reminderInterval; // in minutes
    final endTime = reminderEndTime;

    debugPrint('[ReminderProvider] _scheduleNextSmartReminder: consumed=$consumed  goal=$dailyGoal  interval=${intervalMins}min  intakes=${todayIntakes.length}');

    // Cancel and stop if goal is met.
    if (consumed >= dailyGoal) {
      debugPrint('[ReminderProvider] Goal met — cancelling all reminders.');
      await _notificationService.cancelAllReminders();
      return;
    }

    final nextTime = SmartReminderEngine.nextReminderTime(
      todayIntakes: todayIntakes,
      intervalMinutes: intervalMins,
      endTimeStr: endTime,
    );

    final recommended = SmartReminderEngine.recommendedAmount(
      dailyGoal: dailyGoal,
      consumed: consumed,
      intervalMinutes: intervalMins,
      endTimeStr: endTime,
    );

    debugPrint('[ReminderProvider] nextTime=$nextTime  recommended=${recommended}ml');

    await _notificationService.scheduleSmartReminder(
      scheduledTime: nextTime,
      recommendedAmount: recommended,
    );
  }
}