import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/features/history/screens/hydration_timeline_screen.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaterProvider>().loadDailyTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, waterProvider, _) {
        final dailyTotals = waterProvider.dailyTotals;
        final sortedDates = dailyTotals.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedDates.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await waterProvider.loadDailyTotals();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: sortedDates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final consumed = dailyTotals[date] ?? 0;
              return _DailySummaryCard(
                date: date,
                consumed: consumed,
                onTap: () => _openTimeline(context, date),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_outlined,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No History Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start drinking water to see your hydration history here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.local_drink_outlined),
              label: const Text('Log First Drink'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTimeline(BuildContext context, String date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HydrationTimelineScreen(date: date),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final String date;
  final int consumed;
  final VoidCallback onTap;

  const _DailySummaryCard({
    required this.date,
    required this.consumed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();
    final dailyGoal = userProvider.userSettings?.dailyGoal ?? 2500;
    final percentage = dailyGoal > 0 ? (consumed / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final remaining = (dailyGoal - consumed).clamp(0, dailyGoal);
    final parsedDate = date_utils.AppDateUtils.parseDate(date);
    final isToday = date_utils.AppDateUtils.isToday(parsedDate);
    final isYesterday = date_utils.AppDateUtils.isYesterday(parsedDate);

    String displayDate;
    if (isToday) {
      displayDate = 'Today';
    } else if (isYesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = date_utils.AppDateUtils.formatDisplayDate(parsedDate);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getProgressColor(percentage).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getProgressIcon(percentage),
                  color: _getProgressColor(percentage),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayDate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LIVE',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date_utils.AppDateUtils.formatFullDate(parsedDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStat(
                          context,
                          'Goal',
                          '$dailyGoal ml',
                          theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          context,
                          'Drank',
                          '$consumed ml',
                          _getProgressColor(percentage),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(percentage * 100).round()}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getProgressColor(percentage),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$remaining ml left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.75) return Colors.blue;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getProgressIcon(double percentage) {
    if (percentage >= 1.0) return Icons.check_circle_outlined;
    if (percentage >= 0.75) return Icons.water_drop_outlined;
    if (percentage >= 0.5) return Icons.water_drop_outlined;
    return Icons.water_drop_outlined;
  }
}