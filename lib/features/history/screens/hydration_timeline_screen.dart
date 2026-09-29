import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/data/models/water_intake.dart';
import 'package:smart_water_reminder/features/history/widgets/intake_tile.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';

class HydrationTimelineScreen extends StatefulWidget {
  final String date;

  const HydrationTimelineScreen({super.key, required this.date});

  @override
  State<HydrationTimelineScreen> createState() => _HydrationTimelineScreenState();
}

class _HydrationTimelineScreenState extends State<HydrationTimelineScreen> {
  late List<WaterIntake> _intakes;
  WaterIntake? _deletedIntake;
  int _deletedIndex = -1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIntakes();
  }

  Future<void> _loadIntakes() async {
    final waterProvider = context.read<WaterProvider>();
    final intakes = await waterProvider.getWaterIntakeForDate(widget.date);
    setState(() {
      _intakes = intakes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = date_utils.AppDateUtils.parseDate(widget.date);
    final isToday = date_utils.AppDateUtils.isToday(parsedDate);
    final displayDate = isToday
        ? 'Today'
        : date_utils.AppDateUtils.isYesterday(parsedDate)
            ? 'Yesterday'
            : date_utils.AppDateUtils.formatDisplayDate(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hydration Timeline'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? _buildLoadingState(context)
          : _intakes.isEmpty
              ? _buildEmptyState(context, displayDate)
              : _buildTimeline(context, displayDate),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Loading timeline...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String displayDate) {
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
                Icons.timeline_outlined,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Intakes for $displayDate',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start drinking water to build your timeline.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, String displayDate) {
    final grouped = _groupByTimeOfDay(_intakes);

    return RefreshIndicator(
      onRefresh: _loadIntakes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildHeader(context, displayDate),
          const SizedBox(height: 24),
          ..._buildTimeSections(context, grouped),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayDate) {
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();
    final dailyGoal = userProvider.userSettings?.dailyGoal ?? 2500;
    final totalConsumed = _intakes.fold(0, (sum, i) => sum + i.amount);
    final percentage = dailyGoal > 0 ? (totalConsumed / dailyGoal).clamp(0.0, 1.0) : 0.0;

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
        children: [
          Text(
            displayDate,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeaderStat(
                label: 'Total',
                value: '$totalConsumed ml',
                color: theme.colorScheme.primary,
              ),
              _HeaderStat(
                label: 'Goal',
                value: '$dailyGoal ml',
                color: theme.colorScheme.secondary,
              ),
              _HeaderStat(
                label: 'Progress',
                value: '${(percentage * 100).round()}%',
                color: percentage >= 1.0 ? Colors.green : theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, List<WaterIntake>> _groupByTimeOfDay(List<WaterIntake> intakes) {
    final groups = {
      'Morning': <WaterIntake>[],
      'Afternoon': <WaterIntake>[],
      'Evening': <WaterIntake>[],
      'Night': <WaterIntake>[],
    };

    for (final intake in intakes) {
      final hour = intake.timestamp.hour;
      if (hour < 12) {
        groups['Morning']!.add(intake);
      } else if (hour < 17) {
        groups['Afternoon']!.add(intake);
      } else if (hour < 21) {
        groups['Evening']!.add(intake);
      } else {
        groups['Night']!.add(intake);
      }
    }

    return groups;
  }

  List<Widget> _buildTimeSections(BuildContext context, Map<String, List<WaterIntake>> grouped) {
    final theme = Theme.of(context);
    final sections = <Widget>[];

    final order = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final colors = {
      'Morning': Colors.amber,
      'Afternoon': Colors.orange,
      'Evening': Colors.deepPurple,
      'Night': Colors.indigo,
    };

    for (final section in order) {
      final intakes = grouped[section] ?? [];
      if (intakes.isEmpty) continue;

      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[section],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  section,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors[section],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors[section]!.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${intakes.length} drink${intakes.length > 1 ? 's' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors[section],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...intakes.asMap().entries.map((entry) {
              final index = entry.key;
              final intake = entry.value;
              final isLast = index == intakes.length - 1;
              return IntakeTile(
                intake: intake,
                isLast: isLast,
                sectionColor: colors[section]!,
                onDelete: () => _deleteIntake(intake),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return sections;
  }

  void _deleteIntake(WaterIntake intake) {
    final index = _intakes.indexWhere((i) => i.id == intake.id);
    if (index == -1) return;

    setState(() {
      _deletedIntake = intake;
      _deletedIndex = index;
      _intakes.removeAt(index);
    });

    context.read<WaterProvider>().deleteWaterIntake(intake.id!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${intake.amount} ml removed'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _undoDelete() {
    if (_deletedIntake == null) return;

    setState(() {
      _intakes.insert(_deletedIndex, _deletedIntake!);
    });

    context.read<WaterProvider>().restoreHistoricalIntake(_deletedIntake!);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_deletedIntake!.amount} ml restored'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    _deletedIntake = null;
    _deletedIndex = -1;
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}