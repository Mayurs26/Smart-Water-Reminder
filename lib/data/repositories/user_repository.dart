import 'package:smart_water_reminder/data/database/database_service.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';

class UserRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<UserSettings?> getUserSettings() async {
    return await _databaseService.getUserSettings();
  }

  Future<int> saveUserSettings(UserSettings settings) async {
    return await _databaseService.insertUserSettings(settings);
  }

  Future<int> updateUserSettings(UserSettings settings) async {
    return await _databaseService.updateUserSettings(settings);
  }

  Future<int> clearAllData() async {
    return await _databaseService.clearAllData();
  }
}