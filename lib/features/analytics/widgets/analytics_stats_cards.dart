import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/analytics/models/analytics_data.dart';

class AnalyticsStatsCards extends StatelessWidget {
  final AnalyticsData data;
  final int dailyGoal;

  const AnalyticsStatsCards({
    super.key,
    required this.data,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Avg Daily',
                value: '${data.averageDailyIntake} ml',
                icon: Icons.trending_up_outlined,
                color: theme.colorScheme.primary,
                subtitle: 'Average intake',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Completion',
                value: '${data.monthlyCompletionPercentage.toStringAsFixed(0)}%',
                icon: Icons.percent_outlined,
                color: theme.colorScheme.secondary,
                subtitle: 'Monthly goal hit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Current Streak',
                value: '${data.currentStreak} days',
                icon: Icons.local_fire_department_outlined,
                color: Colors.orange,
                subtitle: 'Consecutive days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Best Streak',
                value: '${data.longestStreak} days',
                icon: Icons.emoji_events_outlined,
                color: Colors.amber,
                subtitle: 'All-time record',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'Best Day',
          value: data.bestHydrationDay,
          icon: Icons.star_outlined,
          color: theme.colorScheme.tertiary,
          subtitle: 'Highest intake day',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}