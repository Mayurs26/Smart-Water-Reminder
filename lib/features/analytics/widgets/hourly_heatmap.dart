import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/analytics/models/analytics_data.dart';

class HourlyHeatmap extends StatelessWidget {
  final AnalyticsData data;
  final int dailyGoal;

  const HourlyHeatmap({
    super.key,
    required this.data,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distribution = data.hourDistribution;
    final maxAmount = distribution.values.isEmpty ? 0 : distribution.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Drinking Pattern',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last 30 days',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(24, (hour) {
                final amount = distribution[hour] ?? 0;
                final intensity = maxAmount > 0 ? amount / maxAmount : 0.0;
                final color = _getIntensityColor(intensity, theme);
                final isPeak = amount == maxAmount && maxAmount > 0;

                return Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPeak)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PEAK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: intensity > 0.5
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '$amount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: intensity > 0.5
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatHour(hour),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Color _getIntensityColor(double intensity, ThemeData theme) {
    if (intensity == 0) {
      return theme.colorScheme.surfaceContainerHighest;
    } else if (intensity < 0.25) {
      return theme.colorScheme.primary.withValues(alpha: 0.2);
    } else if (intensity < 0.5) {
      return theme.colorScheme.primary.withValues(alpha: 0.4);
    } else if (intensity < 0.75) {
      return theme.colorScheme.primary.withValues(alpha: 0.7);
    } else {
      return theme.colorScheme.primary;
    }
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: theme.colorScheme.surfaceContainerHighest,
          label: 'None',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          label: 'Low',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
          label: 'Medium',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: theme.colorScheme.primary,
          label: 'High',
        ),
      ],
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
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