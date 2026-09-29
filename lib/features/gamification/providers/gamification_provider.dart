import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_water_reminder/features/gamification/models/achievement.dart';

class GamificationProvider extends ChangeNotifier {
  static const String _xpKey = 'gamification_total_xp';
  static const String _achievementsKey = 'gamification_achievements';
  static const String _streakKey = 'gamification_streak_data';
  static const String _challengesKey = 'gamification_daily_challenges';
  static const String _lastChallengeDateKey = 'gamification_last_challenge_date';

  final SharedPreferences _prefs;

  int _totalXp = 0;
  List<Achievement> _achievements = [];
  StreakData _streakData = const StreakData();
  List<DailyChallenge> _dailyChallenges = [];
  DateTime? _lastChallengeDate;
  UserLevel _userLevel = UserLevel.fromTotalXp(0);

  bool _showGoalCelebration = false;
  bool _justLeveledUp = false;
  bool _goalJustCompleted = false;
  int _newLevel = 1;
  List<Achievement> _newlyUnlockedAchievements = [];

  GamificationProvider(this._prefs) {
    _loadData();
  }

  int get totalXp => _totalXp;
  List<Achievement> get achievements => _achievements;
  StreakData get streakData => _streakData;
  List<DailyChallenge> get dailyChallenges => _dailyChallenges;
  UserLevel get userLevel => _userLevel;
  
  bool get showGoalCelebration => _showGoalCelebration;
  bool get justLeveledUp => _justLeveledUp;
  bool get goalJustCompleted => _goalJustCompleted;
  int get newLevel => _newLevel;
  List<Achievement> get newlyUnlockedAchievements => _newlyUnlockedAchievements;

  void dismissCelebration() {
    _showGoalCelebration = false;
    _justLeveledUp = false;
    _goalJustCompleted = false;
    _newlyUnlockedAchievements = [];
    notifyListeners();
  }

  Future<void> _loadData() async {
    _totalXp = _prefs.getInt(_xpKey) ?? 0;
    _userLevel = UserLevel.fromTotalXp(_totalXp);

    final achievementsJson = _prefs.getStringList(_achievementsKey) ?? [];
    _achievements = Achievement.getAllAchievements().map((a) {
      final json = achievementsJson.firstWhere(
        (j) => j.startsWith('${a.type.name}:'),
        orElse: () => '',
      );
      if (json.isEmpty) return a;
      final parts = json.split(':');
      return a.copyWith(
        isUnlocked: parts[1] == 'true',
        unlockedAt: parts.length > 2 && parts[2].isNotEmpty
            ? DateTime.parse(parts[2])
            : null,
      );
    }).toList();

    final streakJson = _prefs.getString(_streakKey);
    if (streakJson != null) {
      final parts = streakJson.split('|');
      _streakData = StreakData(
        currentStreak: int.parse(parts[0]),
        longestStreak: int.parse(parts[1]),
        lastCompletedDate: parts[2].isNotEmpty ? DateTime.parse(parts[2]) : null,
        completionMap: _parseCompletionMap(parts[3]),
      );
    }

    final challengesJson = _prefs.getStringList(_challengesKey) ?? [];
    _dailyChallenges = challengesJson.map((j) => _parseChallenge(j)).toList();

    final lastChallengeStr = _prefs.getString(_lastChallengeDateKey);
    if (lastChallengeStr != null) {
      _lastChallengeDate = DateTime.parse(lastChallengeStr);
    }

    _generateDailyChallengesIfNeeded();
    notifyListeners();
  }

  Map<String, bool> _parseCompletionMap(String str) {
    if (str.isEmpty) return {};
    return str.split(',').fold(<String, bool>{}, (map, pair) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1] == 'true';
      }
      return map;
    });
  }

  String _encodeCompletionMap(Map<String, bool> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  DailyChallenge _parseChallenge(String json) {
    final parts = json.split('|');
    return DailyChallenge(
      id: parts[0],
      title: parts[1],
      description: parts[2],
      targetValue: int.parse(parts[3]),
      currentProgress: int.parse(parts[4]),
      xpReward: int.parse(parts[5]),
      type: ChallengeType.values.firstWhere(
        (t) => t.name == parts[6],
        orElse: () => ChallengeType.drinkAmount,
      ),
      date: DateTime.parse(parts[7]),
      isCompleted: parts[8] == 'true',
      completedAt: parts.length > 9 && parts[9].isNotEmpty
          ? DateTime.parse(parts[9])
          : null,
    );
  }

  String _encodeChallenge(DailyChallenge c) {
    return '${c.id}|${c.title}|${c.description}|${c.targetValue}|${c.currentProgress}|${c.xpReward}|${c.type.name}|${c.date.toIso8601String()}|${c.isCompleted}|${c.completedAt?.toIso8601String() ?? ''}';
  }

  Future<void> _saveData() async {
    await _prefs.setInt(_xpKey, _totalXp);

    final achievementsJson = _achievements.map((a) {
      return '${a.type.name}:${a.isUnlocked}:${a.unlockedAt?.toIso8601String() ?? ''}';
    }).toList();
    await _prefs.setStringList(_achievementsKey, achievementsJson);

    final streakStr =
        '${_streakData.currentStreak}|${_streakData.longestStreak}|${_streakData.lastCompletedDate?.toIso8601String() ?? ''}|${_encodeCompletionMap(_streakData.completionMap)}';
    await _prefs.setString(_streakKey, streakStr);

    await _prefs.setStringList(
      _challengesKey,
      _dailyChallenges.map(_encodeChallenge).toList(),
    );

    if (_lastChallengeDate != null) {
      await _prefs.setString(
        _lastChallengeDateKey,
        _lastChallengeDate!.toIso8601String(),
      );
    }
  }

  void _generateDailyChallengesIfNeeded() {
    final today = DateTime.now();
    final todayStr = _dateToString(today);

    if (_lastChallengeDate != null && _dateToString(_lastChallengeDate!) == todayStr) {
      return;
    }

    _lastChallengeDate = today;
    _dailyChallenges = _generateChallengesForDate(today);
    _saveData();
  }

  List<DailyChallenge> _generateChallengesForDate(DateTime date) {
    return [
      DailyChallenge(
        id: 'daily_goal',
        title: 'Daily Goal',
        description: 'Reach your daily water goal',
        targetValue: 1,
        currentProgress: 0,
        xpReward: 50,
        type: ChallengeType.drinkAmount,
        date: date,
      ),
      DailyChallenge(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Drink 500ml before 9 AM',
        targetValue: 500,
        currentProgress: 0,
        xpReward: 100,
        type: ChallengeType.earlyDrink,
        date: date,
      ),
      DailyChallenge(
        id: 'extra_hydration',
        title: 'Extra Hydration',
        description: 'Drink 250ml more than your goal',
        targetValue: 1,
        currentProgress: 0,
        xpReward: 75,
        type: ChallengeType.customGoal,
        date: date,
      ),
    ];
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> addXp(int xp, {String? source}) async {
    _totalXp += xp;
    final newLevel = UserLevel.fromTotalXp(_totalXp);
    final leveledUp = newLevel.level > _userLevel.level;
    _userLevel = newLevel;

    if (leveledUp) {
      _justLeveledUp = true;
      _newLevel = newLevel.level;
    }

    await _saveData();
    notifyListeners();

    if (leveledUp) {
      _checkLevelAchievements();
    }
  }

  Future<void> onWaterAdded(int amount, int dailyGoal, int currentTotal) async {
    final todayStr = _dateToString(DateTime.now());

    _justLeveledUp = false;
    _goalJustCompleted = false;
    _newlyUnlockedAchievements = [];

    // Update streak
    if (currentTotal >= dailyGoal && !_streakData.isCompleted(todayStr)) {
      _goalJustCompleted = true;
      final newCompletionMap = Map<String, bool>.from(_streakData.completionMap);
      newCompletionMap[todayStr] = true;

      int newStreak = _streakData.currentStreak + 1;
      DateTime? lastDate = _streakData.lastCompletedDate;
      if (lastDate != null) {
        final diff = DateTime.now().difference(lastDate).inDays;
        if (diff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final newLongest = newStreak > _streakData.longestStreak ? newStreak : _streakData.longestStreak;

      _streakData = _streakData.copyWith(
        currentStreak: newStreak,
        longestStreak: newLongest,
        lastCompletedDate: DateTime.now(),
        completionMap: newCompletionMap,
      );

      await addXp(25, source: 'streak');
    }

    // Update daily challenges
    for (int i = 0; i < _dailyChallenges.length; i++) {
      final challenge = _dailyChallenges[i];
      if (challenge.isCompleted) continue;

      int newProgress = challenge.currentProgress;
      bool completed = false;

      switch (challenge.type) {
        case ChallengeType.drinkAmount:
          if (currentTotal >= dailyGoal) {
            newProgress = 1;
            completed = true;
          }
          break;
        case ChallengeType.earlyDrink:
          final now = DateTime.now();
          if (now.hour < 9) {
            newProgress += amount;
            if (newProgress >= challenge.targetValue) completed = true;
          }
          break;
        case ChallengeType.customGoal:
          if (currentTotal >= dailyGoal + 250) {
            newProgress = 1;
            completed = true;
          }
          break;
        default:
          break;
      }

      if (newProgress != challenge.currentProgress || completed) {
        _dailyChallenges[i] = challenge.copyWith(
          currentProgress: newProgress,
          isCompleted: completed,
          completedAt: completed ? DateTime.now() : null,
        );
        if (completed) {
          await addXp(challenge.xpReward, source: 'challenge_${challenge.id}');
        }
      }
    }

    // Check achievements
    await _checkAchievements(currentTotal, dailyGoal);
    await _saveData();
    
    if (_goalJustCompleted || _justLeveledUp || _newlyUnlockedAchievements.isNotEmpty) {
      _showGoalCelebration = true;
    }
    
    notifyListeners();
  }

  Future<void> _checkAchievements(int currentTotal, int dailyGoal) async {
    final now = DateTime.now();

    // First Glass
    await _unlockIfNotUnlocked(AchievementType.firstGlass);

    // 3-Day Streak
    if (_streakData.currentStreak >= 3) {
      await _unlockIfNotUnlocked(AchievementType.streak3);
    }

    // 7-Day Streak
    if (_streakData.currentStreak >= 7) {
      await _unlockIfNotUnlocked(AchievementType.streak7);
    }

    // 30-Day Streak
    if (_streakData.currentStreak >= 30) {
      await _unlockIfNotUnlocked(AchievementType.streak30);
    }

    // Goal Crusher (exceed by 50%)
    if (currentTotal >= dailyGoal * 1.5) {
      await _unlockIfNotUnlocked(AchievementType.goalCrusher);
    }

    // Early Bird
    if (now.hour < 9) {
      final morningIntake = _getMorningIntake();
      if (morningIntake >= 500) {
        await _unlockIfNotUnlocked(AchievementType.earlyBird);
      }
    }

    // Night Owl
    if (now.hour >= 22) {
      await _unlockIfNotUnlocked(AchievementType.nightOwl);
    }

    // Hydration Master (Level 10)
    if (_userLevel.level >= 10) {
      await _unlockIfNotUnlocked(AchievementType.hydrationMaster);
    }
  }

  int _getMorningIntake() {
    // This would need to be calculated from actual intake data
    // For now, return 0 as placeholder
    return 0;
  }

  Future<void> _unlockIfNotUnlocked(AchievementType type) async {
    final index = _achievements.indexWhere((a) => a.type == type);
    if (index != -1 && !_achievements[index].isUnlocked) {
      final achievement = _achievements[index];
      _achievements[index] = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      if (!_newlyUnlockedAchievements.any((a) => a.type == type)) {
        _newlyUnlockedAchievements.add(_achievements[index]);
      }
      await addXp(achievement.xpReward, source: 'achievement_${type.name}');
    }
  }

  Future<void> _checkLevelAchievements() async {
    if (_userLevel.level >= 10) {
      await _unlockIfNotUnlocked(AchievementType.hydrationMaster);
    }
  }

  Future<void> resetAllData() async {
    _totalXp = 0;
    _userLevel = UserLevel.fromTotalXp(0);
    _achievements = Achievement.getAllAchievements();
    _streakData = const StreakData();
    _dailyChallenges = [];
    _lastChallengeDate = null;
    await _saveData();
    notifyListeners();
  }
}