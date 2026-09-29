import 'package:flutter/foundation.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';
import 'package:smart_water_reminder/data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  UserSettings? _userSettings;
  bool _isLoading = false;

  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _userSettings?.isOnboarded ?? false;

  Future<void> loadUserSettings() async {
    _isLoading = true;
    notifyListeners();

    _userSettings = await _repository.getUserSettings();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    await _repository.saveUserSettings(settings);
    _userSettings = settings;
    notifyListeners();
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    await _repository.updateUserSettings(settings);
    _userSettings = settings;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
    _userSettings = null;
    notifyListeners();
  }

  void updateName(String name) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(name: name);
      notifyListeners();
    }
  }

  void updateAge(int age) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(age: age);
      notifyListeners();
    }
  }

  void updateWeight(double weight) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(weight: weight);
      notifyListeners();
    }
  }

  void updateGender(String gender) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(gender: gender);
      notifyListeners();
    }
  }

  void updateDailyGoal(int goal) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(dailyGoal: goal);
      notifyListeners();
    }
  }

  void updateWakeUpTime(String time) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(wakeUpTime: time);
      notifyListeners();
    }
  }

  void updateSleepTime(String time) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(sleepTime: time);
      notifyListeners();
    }
  }

  void updateReminderInterval(int interval) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(reminderInterval: interval);
      notifyListeners();
    }
  }

  void updateRemindersEnabled(bool enabled) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(remindersEnabled: enabled);
      notifyListeners();
    }
  }

  void updateReminderStartTime(String time) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(reminderStartTime: time);
      notifyListeners();
    }
  }

  void updateReminderEndTime(String time) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(reminderEndTime: time);
      notifyListeners();
    }
  }

  void updateThemeMode(ThemeModeType mode) {
    if (_userSettings != null) {
      _userSettings = _userSettings!.copyWith(themeMode: mode);
      notifyListeners();
    }
  }
}