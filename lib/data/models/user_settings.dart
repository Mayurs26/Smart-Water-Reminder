enum ThemeModeType { system, light, dark }

class UserSettings {
  final String? name;
  final int? age;
  final double? weight;
  final int dailyGoal;
  final String wakeUpTime;
  final String sleepTime;
  final int reminderInterval;
  final bool remindersEnabled;
  final String reminderStartTime;
  final String reminderEndTime;
  final String activityLevel;
  final ThemeModeType themeMode;

  final String? gender;

  UserSettings({
    this.name,
    this.age,
    this.weight,
    this.gender,
    required this.dailyGoal,
    required this.wakeUpTime,
    required this.sleepTime,
    required this.reminderInterval,
    required this.remindersEnabled,
    required this.reminderStartTime,
    required this.reminderEndTime,
    required this.activityLevel,
    required this.themeMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'gender': gender,
      'daily_goal': dailyGoal,
      'wake_up_time': wakeUpTime,
      'sleep_time': sleepTime,
      'reminder_interval': reminderInterval,
      'reminders_enabled': remindersEnabled ? 1 : 0,
      'reminder_start_time': reminderStartTime,
      'reminder_end_time': reminderEndTime,
      'activity_level': activityLevel,
      'theme_mode': themeMode.index,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      name: map['name'] as String?,
      age: map['age'] as int?,
      weight: map['weight'] as double?,
      gender: map['gender'] as String?,
      dailyGoal: map['daily_goal'] as int? ?? 2500,
      wakeUpTime: map['wake_up_time'] as String? ?? '07:00',
      sleepTime: map['sleep_time'] as String? ?? '22:00',
      reminderInterval: map['reminder_interval'] as int? ?? 60,
      remindersEnabled: (map['reminders_enabled'] as int? ?? 1) == 1,
      reminderStartTime: map['reminder_start_time'] as String? ?? '09:00',
      reminderEndTime: map['reminder_end_time'] as String? ?? '21:00',
      activityLevel: map['activity_level'] as String? ?? 'moderate',
      themeMode: ThemeModeType.values[map['theme_mode'] as int? ?? 0],
    );
  }

  UserSettings copyWith({
    String? name,
    int? age,
    double? weight,
    String? gender,
    int? dailyGoal,
    String? wakeUpTime,
    String? sleepTime,
    int? reminderInterval,
    bool? remindersEnabled,
    String? reminderStartTime,
    String? reminderEndTime,
    String? activityLevel,
    ThemeModeType? themeMode,
  }) {
    return UserSettings(
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderStartTime: reminderStartTime ?? this.reminderStartTime,
      reminderEndTime: reminderEndTime ?? this.reminderEndTime,
      activityLevel: activityLevel ?? this.activityLevel,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  int get suggestedDailyGoal {
    if (weight == null) return 2500;
    int base = (weight! * 35).round();
    if (activityLevel == 'high' || activityLevel == 'intense') {
      base += 500;
    }
    // Adjust slightly for gender if known (some standard formulas suggest a small difference, but we will stick to baseline)
    return base < 2200 ? 2200 : base;
  }

  bool get isOnboarded => name != null && weight != null && gender != null;

  @override
  String toString() {
    return 'UserSettings(name: $name, age: $age, weight: $weight, gender: $gender, dailyGoal: $dailyGoal, '
        'wakeUpTime: $wakeUpTime, sleepTime: $sleepTime, reminderInterval: $reminderInterval, '
        'remindersEnabled: $remindersEnabled, reminderStartTime: $reminderStartTime, '
        'reminderEndTime: $reminderEndTime, activityLevel: $activityLevel, themeMode: $themeMode)';
  }
}