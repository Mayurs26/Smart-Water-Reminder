import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/data/models/water_intake.dart';
import 'package:smart_water_reminder/data/repositories/water_repository.dart';

class WaterProvider extends ChangeNotifier {
  final WaterRepository _repository = WaterRepository();

  List<WaterIntake> _todayIntakes = [];
  int _totalConsumed = 0;
  Map<String, int> _dailyTotals = {};
  bool _isLoading = false;
  String _currentDate = '';
  WaterIntake? _lastAddedIntake;

  // Callback fired on every intake change (used for reminder rescheduling).
  Function(int)? _onWaterChanged;

  // Midnight-reset timer.
  Timer? _midnightTimer;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<WaterIntake> get todayIntakes => _todayIntakes;
  int get totalConsumed => _totalConsumed;
  Map<String, int> get dailyTotals => _dailyTotals;
  bool get isLoading => _isLoading;
  String get currentDate => _currentDate;
  WaterIntake? get lastAddedIntake => _lastAddedIntake;
  bool get canUndo => _lastAddedIntake != null;
  int get glassCount => _todayIntakes.length;

  // ── Initialisation / lifecycle ─────────────────────────────────────────────

  void setOnWaterChanged(Function(int) callback) {
    _onWaterChanged = callback;
  }

  /// Sets today's date string and loads data if the date changed.
  /// Also arms the midnight-reset timer.
  void setCurrentDate(String date) {
    if (_currentDate != date) {
      _currentDate = date;
      loadTodayData();
    }
    _scheduleMidnightReset();
  }

  /// Arms (or re-arms) a one-shot timer that fires at midnight to roll over
  /// to the new day without needing an app restart.
  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final untilMidnight = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(untilMidnight, () {
      // Roll over: the new date becomes "today".
      final newDate = date_utils.AppDateUtils.getTodayString();
      _currentDate = newDate;
      _todayIntakes = [];
      _totalConsumed = 0;
      _lastAddedIntake = null;
      _onWaterChanged?.call(0);
      notifyListeners();
      loadTodayData();
      // Rearm for the next midnight.
      _scheduleMidnightReset();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> loadTodayData() async {
    if (_currentDate.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    _todayIntakes = await _repository.getWaterIntakeForDate(_currentDate);
    _totalConsumed = await _repository.getTotalConsumedForDate(_currentDate);
    _lastAddedIntake = _todayIntakes.isNotEmpty ? _todayIntakes.first : null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDailyTotals() async {
    _dailyTotals = await _repository.getDailyTotals();
    notifyListeners();
  }

  // ── Write operations ───────────────────────────────────────────────────────

  Future<void> addWaterIntake(int amount) async {
    final now = DateTime.now();
    final intake = WaterIntake(
      amount: amount,
      timestamp: now,
      date: _currentDate,
    );

    await _repository.addWaterIntake(intake);
    _todayIntakes.insert(0, intake);
    _totalConsumed += amount;
    _dailyTotals[_currentDate] = _totalConsumed;
    _lastAddedIntake = intake;

    _onWaterChanged?.call(_totalConsumed);
    notifyListeners();
  }

  Future<void> restoreHistoricalIntake(WaterIntake intake) async {
    await _repository.addWaterIntake(intake);
    if (intake.date == _currentDate) {
      _todayIntakes.add(intake);
      _todayIntakes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _totalConsumed += intake.amount;
      _lastAddedIntake = _todayIntakes.first;
      _onWaterChanged?.call(_totalConsumed);
    }

    _dailyTotals[intake.date] = (_dailyTotals[intake.date] ?? 0) + intake.amount;
    notifyListeners();
  }

  Future<void> undoLastIntake() async {
    if (_lastAddedIntake == null || _lastAddedIntake!.id == null) return;

    await _repository.deleteWaterIntake(_lastAddedIntake!.id!);
    _totalConsumed -= _lastAddedIntake!.amount;
    _todayIntakes.removeWhere((i) => i.id == _lastAddedIntake!.id);
    _dailyTotals[_currentDate] = _totalConsumed;
    _lastAddedIntake = _todayIntakes.isNotEmpty ? _todayIntakes.first : null;

    _onWaterChanged?.call(_totalConsumed);
    notifyListeners();
  }

  Future<void> deleteWaterIntake(int id) async {
    final intake = _todayIntakes.firstWhere(
      (i) => i.id == id,
      orElse: () => WaterIntake(amount: 0, timestamp: DateTime.now(), date: _currentDate),
    );
    if (intake.id != null) {
      await _repository.deleteWaterIntake(intake.id!);
      _todayIntakes.removeWhere((i) => i.id == id);
      _totalConsumed -= intake.amount;
      _dailyTotals[_currentDate] = _totalConsumed;
      if (_lastAddedIntake?.id == id) {
        _lastAddedIntake = _todayIntakes.isNotEmpty ? _todayIntakes.first : null;
      }
      _onWaterChanged?.call(_totalConsumed);
      notifyListeners();
    }
  }

  Future<void> clearTodayData() async {
    await _repository.clearTodayData(_currentDate);
    _todayIntakes.clear();
    _totalConsumed = 0;
    _dailyTotals[_currentDate] = 0;
    _lastAddedIntake = null;
    _onWaterChanged?.call(0);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
    _todayIntakes.clear();
    _totalConsumed = 0;
    _dailyTotals.clear();
    _lastAddedIntake = null;
    _onWaterChanged?.call(0);
    notifyListeners();
  }

  // ── Query helpers ──────────────────────────────────────────────────────────

  Future<List<WaterIntake>> getWaterIntakeForDate(String date) async {
    return await _repository.getWaterIntakeForDate(date);
  }

  /// Returns all historical intakes from the database — single query, no loops.
  Future<List<WaterIntake>> getAllIntakes() async {
    return await _repository.getAllWaterIntake();
  }

  double getProgress(int dailyGoal) {
    if (dailyGoal <= 0) return 0;
    return (_totalConsumed / dailyGoal).clamp(0.0, 1.0);
  }

  int getRemaining(int dailyGoal) {
    return (dailyGoal - _totalConsumed).clamp(0, dailyGoal);
  }
}