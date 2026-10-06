class AppConstants {
  static const String appName = 'Smart Water Reminder';
  
  static const String userSettingsTable = 'user_settings';
  static const String waterIntakeTable = 'water_intake';
  
  static const String keyIsOnboarded = 'is_onboarded';
  static const String keyUserName = 'user_name';
  static const String keyUserAge = 'user_age';
  static const String keyUserWeight = 'user_weight';
  static const String keyDailyGoal = 'daily_goal';
  static const String keyWakeUpTime = 'wake_up_time';
  static const String keySleepTime = 'sleep_time';
  static const String keyReminderInterval = 'reminder_interval';
  static const String keyRemindersEnabled = 'reminders_enabled';
  static const String keyReminderStartTime = 'reminder_start_time';
  static const String keyReminderEndTime = 'reminder_end_time';
  static const String keyThemeMode = 'theme_mode';

  // Reminder interval is stored and used in MINUTES.
  // Supported presets shown in RemindersScreen.
  static const List<int> reminderIntervalPresets = [1, 2, 5, 10, 15, 30, 60, 120];
  static const int defaultReminderInterval = 60; // 60 minutes = 1 hour
  static const String defaultWakeUpTime = '07:00';
  static const String defaultSleepTime = '22:00';
  static const String defaultReminderStartTime = '09:00';
  static const String defaultReminderEndTime = '21:00';
  static const int defaultDailyGoal = 2500;
  
  static const List<int> quickAddAmounts = [100, 200, 250, 500];
  
  static const int notificationId = 1001;
  static const String notificationChannelId = 'water_reminders';
  static const String notificationChannelName = 'Water Reminders';
  static const String notificationChannelDescription = 'Reminders to drink water throughout the day';

  /// Human-readable label for a reminder interval given in minutes.
  static String intervalLabel(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}