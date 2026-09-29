import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'water_reminder.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.userSettingsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        weight REAL,
        gender TEXT,
        daily_goal INTEGER NOT NULL DEFAULT 2500,
        wake_up_time TEXT NOT NULL DEFAULT '07:00',
        sleep_time TEXT NOT NULL DEFAULT '22:00',
        reminder_interval INTEGER NOT NULL DEFAULT 2,
        reminders_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_start_time TEXT NOT NULL DEFAULT '09:00',
        reminder_end_time TEXT NOT NULL DEFAULT '21:00',
        activity_level TEXT NOT NULL DEFAULT 'moderate',
        theme_mode INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.waterIntakeTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_water_intake_date ON ${AppConstants.waterIntakeTable}(date)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE ${AppConstants.userSettingsTable} 
        ADD COLUMN activity_level TEXT NOT NULL DEFAULT 'moderate'
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE ${AppConstants.userSettingsTable} 
        ADD COLUMN gender TEXT
      ''');
    }
  }

  Future<int> insertUserSettings(UserSettings settings) async {
    final db = await database;
    return await db.insert(
      AppConstants.userSettingsTable,
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserSettings?> getUserSettings() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.userSettingsTable,
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserSettings.fromMap(maps.first);
  }

  Future<int> updateUserSettings(UserSettings settings) async {
    final db = await database;
    return await db.update(
      AppConstants.userSettingsTable,
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> insertWaterIntake(WaterIntake intake) async {
    final db = await database;
    return await db.insert(
      AppConstants.waterIntakeTable,
      intake.toMap(),
    );
  }

  Future<List<WaterIntake>> getWaterIntakeForDate(String date) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.waterIntakeTable,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => WaterIntake.fromMap(map)).toList();
  }

  Future<List<WaterIntake>> getAllWaterIntake() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.waterIntakeTable,
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => WaterIntake.fromMap(map)).toList();
  }

  Future<int> getTotalConsumedForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM ${AppConstants.waterIntakeTable} WHERE date = ?',
      [date],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<String, int>> getDailyTotals() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT date, SUM(amount) as total FROM ${AppConstants.waterIntakeTable} GROUP BY date ORDER BY date DESC',
    );
    return {for (var map in maps) map['date'] as String: (map['total'] as int?) ?? 0};
  }

  Future<int> deleteWaterIntake(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.waterIntakeTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearTodayData(String date) async {
    final db = await database;
    return await db.delete(
      AppConstants.waterIntakeTable,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<int> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.waterIntakeTable);
    return await db.delete(AppConstants.userSettingsTable);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}