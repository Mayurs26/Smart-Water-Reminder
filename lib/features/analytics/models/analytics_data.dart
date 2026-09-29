import 'package:fl_chart/fl_chart.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';

class AnalyticsData {
  final Map<String, int> dailyTotals;
  final List<WaterIntake> allIntakes;
  final int dailyGoal;

  AnalyticsData({
    required this.dailyTotals,
    required this.allIntakes,
    required this.dailyGoal,
  });

  int get averageDailyIntake {
    if (dailyTotals.isEmpty) return 0;
    final sum = dailyTotals.values.fold(0, (a, b) => a + b);
    return (sum / dailyTotals.length).round();
  }

  double get monthlyCompletionPercentage {
    if (dailyTotals.isEmpty) return 0.0;
    final daysWithData = dailyTotals.length;
    final daysCompleted = dailyTotals.values.where((v) => v >= dailyGoal).length;
    return (daysCompleted / daysWithData * 100);
  }

  int get longestStreak {
    if (dailyTotals.isEmpty) return 0;
    
    final sortedDates = dailyTotals.keys.toList()..sort();
    int maxStreak = 0;
    int currentStreak = 0;
    
    for (int i = 0; i < sortedDates.length; i++) {
      final date = DateTime.parse(sortedDates[i]);
      final consumed = dailyTotals[sortedDates[i]] ?? 0;
      
      if (consumed >= dailyGoal) {
        currentStreak++;
        maxStreak = maxStreak < currentStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
      
      // Check for gaps in dates
      if (i < sortedDates.length - 1) {
        final nextDate = DateTime.parse(sortedDates[i + 1]);
        if (nextDate.difference(date).inDays > 1) {
          currentStreak = 0;
        }
      }
    }
    
    return maxStreak;
  }

  int get currentStreak {
    if (dailyTotals.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    int streak = 0;
    DateTime checkDate = today;
    
    // Check if today is complete
    if (dailyTotals[todayStr] != null && dailyTotals[todayStr]! >= dailyGoal) {
      streak = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      checkDate = today.subtract(const Duration(days: 1));
    }
    
    // Check previous days
    for (int i = 0; i < 365; i++) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dailyTotals[dateStr] != null && dailyTotals[dateStr]! >= dailyGoal) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  String get bestHydrationDay {
    if (dailyTotals.isEmpty) return 'N/A';
    
    var bestDate = dailyTotals.keys.first;
    var bestAmount = dailyTotals.values.first;
    
    dailyTotals.forEach((date, amount) {
      if (amount > bestAmount) {
        bestAmount = amount;
        bestDate = date;
      }
    });
    
    final parsed = DateTime.parse(bestDate);
    return '${parsed.day}/${parsed.month} ($bestAmount ml)';
  }

  Map<int, int> get hourDistribution {
    final Map<int, int> distribution = {};
    for (int i = 0; i < 24; i++) {
      distribution[i] = 0;
    }
    
    for (final intake in allIntakes) {
      distribution[intake.timestamp.hour] = (distribution[intake.timestamp.hour] ?? 0) + intake.amount;
    }
    
    return distribution;
  }

  List<FlSpot> get weeklyChartData {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final spots = <FlSpot>[];
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final amount = dailyTotals[dateStr] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount.toDouble()));
    }
    
    return spots;
  }

  List<FlSpot> get monthlyChartData {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final spots = <FlSpot>[];
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final amount = dailyTotals[dateStr] ?? 0;
      spots.add(FlSpot((day - 1).toDouble(), amount.toDouble()));
    }
    
    return spots;
  }
}