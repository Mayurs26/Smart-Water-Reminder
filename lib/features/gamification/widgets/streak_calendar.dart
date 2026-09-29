import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/gamification/models/achievement.dart';

class StreakCalendar extends StatelessWidget {
  final StreakData streakData;
  final int monthsToShow;

  const StreakCalendar({
    super.key,
    required this.streakData,
    this.monthsToShow = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weeks = _generateWeeks(now);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak Calendar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${streakData.currentStreak} day streak',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Best: ${streakData.longestStreak}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(
                      day,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: week.map((date) {
                  if (date == null) {
                    return const SizedBox(width: 36, height: 36);
                  }
                  final dateStr = _dateToString(date);
                  final isCompleted = streakData.isCompleted(dateStr);
                  final isToday = _isSameDay(date, now);
                  final isFuture = date.isAfter(now);

                  return _CalendarDay(
                    day: date.day.toString(),
                    isCompleted: isCompleted,
                    isToday: isToday,
                    isFuture: isFuture,
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  List<List<DateTime?>> _generateWeeks(DateTime now) {
    final weeks = <List<DateTime?>>[];
    final startOfMonth = DateTime(now.year, now.month - monthsToShow + 1, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    DateTime current = startOfMonth.subtract(Duration(days: startOfMonth.weekday - 1));
    
    while (current.isBefore(endOfMonth.add(const Duration(days: 7)))) {
      final week = <DateTime?>[];
      for (int i = 0; i < 7; i++) {
        if (current.isBefore(startOfMonth) || current.isAfter(endOfMonth)) {
          week.add(null);
        } else {
          week.add(current);
        }
        current = current.add(const Duration(days: 1));
      }
      weeks.add(week);
    }
    
    return weeks;
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: Colors.orange,
          label: 'Completed',
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          label: 'Missed',
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          label: 'Today',
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final String day;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;

  const _CalendarDay({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Colors.orange
            : isFuture
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(alpha: 0.2),
        border: isToday && !isCompleted
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          day,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCompleted
                ? Colors.white
                : isFuture
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}