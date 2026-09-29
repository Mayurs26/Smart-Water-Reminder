import 'package:flutter/material.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';

class OnboardingData {
  String name = '';
  int? age;
  double? weight;
  String? gender;
  int dailyGoal = 2500;
  TimeOfDay wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay sleepTime = const TimeOfDay(hour: 22, minute: 0);
  int reminderInterval = 2;
  bool remindersEnabled = true;
  String activityLevel = 'Medium';

  int get suggestedDailyGoal {
    if (weight == null || weight! <= 0) return 2500;
    int base = (weight! * 35).round();
    if (activityLevel == 'high' || activityLevel == 'intense') base += 500;
    return base < 2200 ? 2200 : base;
  }

  UserSettings toUserSettings() {
    return UserSettings(
      name: name.trim().isEmpty ? 'User' : name.trim(),
      age: age,
      weight: weight,
      gender: gender,
      dailyGoal: dailyGoal,
      wakeUpTime: _formatTime(wakeUpTime),
      sleepTime: _formatTime(sleepTime),
      reminderInterval: reminderInterval,
      remindersEnabled: remindersEnabled,
      reminderStartTime: _formatTime(wakeUpTime),
      reminderEndTime: _formatTime(sleepTime),
      activityLevel: activityLevel, // ✅ Add this
      themeMode: ThemeModeType.system,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void updateFromUserSettings(UserSettings settings) {
    name = settings.name ?? '';
    age = settings.age;
    weight = settings.weight;
    gender = settings.gender;
    dailyGoal = settings.dailyGoal;
    wakeUpTime = _parseTime(settings.wakeUpTime);
    sleepTime = _parseTime(settings.sleepTime);
    reminderInterval = settings.reminderInterval;
    remindersEnabled = settings.remindersEnabled;
    activityLevel = settings.activityLevel;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 7, minute: 0);
  }

  bool get isPersonalInfoValid =>
      name.trim().isNotEmpty && weight != null && weight! > 0 && gender != null;
}
