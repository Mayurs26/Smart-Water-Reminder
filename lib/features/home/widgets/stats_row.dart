import 'package:flutter/material.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/data/models/water_intake.dart';

class StatsRow extends StatelessWidget {
  final int glassCount;
  final WaterIntake? lastIntake;
  final VoidCallback? onUndo;
  final bool canUndo;
  final VoidCallback? onIntakesTodayTap;

  const StatsRow({
    super.key,
    required this.glassCount,
    this.lastIntake,
    this.onUndo,
    this.canUndo = false,
    this.onIntakesTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_drink_outlined,
            label: 'Intakes Today',
            value: '$glassCount',
            color: theme.colorScheme.primary,
            onTap: onIntakesTodayTap,
            trailing: onIntakesTodayTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_outlined,
            label: 'Last Drink',
            value: lastIntake != null
                ? date_utils.AppDateUtils.formatTime(lastIntake!.timestamp)
                : '--:--',
            color: theme.colorScheme.secondary,
            onTap: canUndo ? onUndo : null,
            trailing: canUndo
                ? Icon(
                    Icons.undo_outlined,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const Spacer(),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
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
}