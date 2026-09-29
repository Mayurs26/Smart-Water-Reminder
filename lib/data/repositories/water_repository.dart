import 'package:smart_water_reminder/data/database/database_service.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';

class WaterRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> addWaterIntake(WaterIntake intake) async {
    return await _databaseService.insertWaterIntake(intake);
  }

  Future<List<WaterIntake>> getWaterIntakeForDate(String date) async {
    return await _databaseService.getWaterIntakeForDate(date);
  }

  Future<List<WaterIntake>> getAllWaterIntake() async {
    return await _databaseService.getAllWaterIntake();
  }

  Future<int> getTotalConsumedForDate(String date) async {
    return await _databaseService.getTotalConsumedForDate(date);
  }

  Future<Map<String, int>> getDailyTotals() async {
    return await _databaseService.getDailyTotals();
  }

  Future<int> deleteWaterIntake(int id) async {
    return await _databaseService.deleteWaterIntake(id);
  }

  Future<int> clearTodayData(String date) async {
    return await _databaseService.clearTodayData(date);
  }

  Future<int> clearAllData() async {
    return await _databaseService.clearAllData();
  }
}