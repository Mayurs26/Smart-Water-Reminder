import 'package:flutter/material.dart';

enum AchievementType {
  firstGlass,
  streak3,
  streak7,
  streak30,
  hydrationMaster,
  goalCrusher,
  earlyBird,
  nightOwl,
  consistentWeek,
  weekendWarrior,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;
  final int xpReward;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.xpReward,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      type: type,
      title: title,
      description: description,
      icon: icon,
      rarity: rarity,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  static List<Achievement> getAllAchievements() {
    return [
      Achievement(
        type: AchievementType.firstGlass,
        title: 'First Glass',
        description: 'Log your very first water intake',
        icon: Icons.local_drink_outlined,
        rarity: AchievementRarity.common,
        xpReward: 50,
      ),
      Achievement(
        type: AchievementType.streak3,
        title: '3-Day Streak',
        description: 'Hit your daily goal 3 days in a row',
        icon: Icons.local_fire_department_outlined,
        rarity: AchievementRarity.common,
        xpReward: 100,
      ),
      Achievement(
        type: AchievementType.streak7,
        title: 'Week Warrior',
        description: 'Hit your daily goal 7 days in a row',
        icon: Icons.whatshot_outlined,
        rarity: AchievementRarity.rare,
        xpReward: 250,
      ),
      Achievement(
        type: AchievementType.streak30,
        title: 'Monthly Master',
        description: 'Hit your daily goal 30 days in a row',
        icon: Icons.emoji_events_outlined,
        rarity: AchievementRarity.legendary,
        xpReward: 1000,
      ),
      Achievement(
        type: AchievementType.hydrationMaster,
        title: 'Hydration Master',
        description: 'Reach Level 10',
        icon: Icons.military_tech_outlined,
        rarity: AchievementRarity.legendary,
        xpReward: 500,
      ),
      Achievement(
        type: AchievementType.goalCrusher,
        title: 'Goal Crusher',
        description: 'Exceed daily goal by 50% in a single day',
        icon: Icons.rocket_launch_outlined,
        rarity: AchievementRarity.epic,
        xpReward: 300,
      ),
      Achievement(
        type: AchievementType.earlyBird,
        title: 'Early Bird',
        description: 'Drink 500ml before 9 AM',
        icon: Icons.wb_sunny_outlined,
        rarity: AchievementRarity.rare,
        xpReward: 150,
      ),
      Achievement(
        type: AchievementType.nightOwl,
        title: 'Night Owl',
        description: 'Drink water after 10 PM',
        icon: Icons.nights_stay_outlined,
        rarity: AchievementRarity.common,
        xpReward: 50,
      ),
      Achievement(
        type: AchievementType.consistentWeek,
        title: 'Consistent Week',
        description: 'Log water every day for a week',
        icon: Icons.calendar_month_outlined,
        rarity: AchievementRarity.rare,
        xpReward: 200,
      ),
      Achievement(
        type: AchievementType.weekendWarrior,
        title: 'Weekend Warrior',
        description: 'Hit goal on both Saturday and Sunday',
        icon: Icons.weekend_outlined,
        rarity: AchievementRarity.common,
        xpReward: 100,
      ),
    ];
  }
}

class UserLevel {
  final int level;
  final int currentXp;
  final int xpForNextLevel;
  final int totalXpEarned;

  const UserLevel({
    required this.level,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.totalXpEarned,
  });

  double get progress => currentXp / xpForNextLevel;

  int get xpNeededForNext => xpForNextLevel - currentXp;

  static int xpForLevel(int level) {
    if (level <= 1) return 100;
    return 100 + (level - 1) * 50 + (level - 1) * (level - 2) * 25;
  }

  static UserLevel fromTotalXp(int totalXp) {
    int level = 1;
    int xpForNext = xpForLevel(1);
    int remainingXp = totalXp;

    while (remainingXp >= xpForNext) {
      remainingXp -= xpForNext;
      level++;
      xpForNext = xpForLevel(level);
    }

    return UserLevel(
      level: level,
      currentXp: remainingXp,
      xpForNextLevel: xpForNext,
      totalXpEarned: totalXp,
    );
  }

  UserLevel addXp(int xp) {
    return fromTotalXp(totalXpEarned + xp);
  }
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int xpReward;
  final ChallengeType type;
  final DateTime date;
  final bool isCompleted;
  final DateTime? completedAt;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.xpReward,
    required this.type,
    required this.date,
    this.isCompleted = false,
    this.completedAt,
  });

  double get progress => (currentProgress / targetValue).clamp(0.0, 1.0);

  DailyChallenge copyWith({
    int? currentProgress,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyChallenge(
      id: id,
      title: title,
      description: description,
      targetValue: targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      xpReward: xpReward,
      type: type,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum ChallengeType {
  drinkAmount,
  streakMaintain,
  earlyDrink,
  customGoal,
  noReminders,
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final Map<String, bool> completionMap;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.completionMap = const {},
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    Map<String, bool>? completionMap,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      completionMap: completionMap ?? this.completionMap,
    );
  }

  bool isCompleted(String dateStr) => completionMap[dateStr] == true;

  void setCompleted(String dateStr, bool completed) {
    completionMap[dateStr] = completed;
  }
}