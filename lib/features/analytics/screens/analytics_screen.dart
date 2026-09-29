import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';
import 'package:smart_water_reminder/features/analytics/models/analytics_data.dart';
import 'package:smart_water_reminder/features/analytics/widgets/analytics_stats_cards.dart';
import 'package:smart_water_reminder/features/analytics/widgets/hourly_heatmap.dart';
import 'package:smart_water_reminder/features/analytics/widgets/intake_chart.dart';
import 'package:smart_water_reminder/features/analytics/widgets/period_selector.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String? _error;
  List<WaterIntake> _allIntakes = [];
  Map<String, int> _dailyTotals = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final waterProvider = context.read<WaterProvider>();

      // Single DB call for all intakes — no 90-iteration loop
      final allIntakes = await waterProvider.getAllIntakes();

      // Also refresh daily totals
      await waterProvider.loadDailyTotals();

      if (!mounted) return;
      setState(() {
        _allIntakes = allIntakes;
        _dailyTotals = Map<String, int>.from(waterProvider.dailyTotals);
        _isLoading = false;
      });

      _controller.reset();
      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // React to dailyGoal changes only — don't re-trigger DB load
    final userSettings = context.watch<UserProvider>().userSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) return _buildLoadingState(context);

          if (_error != null) {
            return _buildErrorState(context, _error!);
          }

          if (userSettings == null) {
            return _buildEmptyState(context);
          }

          final dailyGoal = userSettings.dailyGoal;

          final data = AnalyticsData(
            dailyTotals: _dailyTotals,
            allIntakes: _allIntakes,
            dailyGoal: dailyGoal,
          );

          if (_dailyTotals.isEmpty && _allIntakes.isEmpty) {
            return _buildNoDataState(context);
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 24),
                          AnalyticsStatsCards(
                              data: data, dailyGoal: dailyGoal),
                          const SizedBox(height: 24),
                          _buildChartSection(context, data),
                          const SizedBox(height: 24),
                          HourlyHeatmap(data: data, dailyGoal: dailyGoal),
                          const SizedBox(height: 24),
                          _buildInsightsSection(context, data),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hydration Analytics',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your progress and build better habits',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, AnalyticsData data) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Intake Trend',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) =>
                  setState(() => _selectedPeriod = period),
            ),
          ],
        ),
        const SizedBox(height: 16),
        IntakeChart(
          data: data,
          period: _selectedPeriod,
          dailyGoal: data.dailyGoal,
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context, AnalyticsData data) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightItem(
            icon: Icons.water_drop_outlined,
            title: 'Average Daily Intake',
            description: '${data.averageDailyIntake} ml per day',
            color: theme.colorScheme.primary,
          ),
          _InsightItem(
            icon: Icons.calendar_month_outlined,
            title: 'Monthly Completion',
            description:
                '${data.monthlyCompletionPercentage.toStringAsFixed(0)}% of days met goal',
            color: theme.colorScheme.secondary,
          ),
          _InsightItem(
            icon: Icons.local_fire_department_outlined,
            title: 'Current Streak',
            description: '${data.currentStreak} consecutive days',
            color: Colors.orange,
          ),
          _InsightItem(
            icon: Icons.star_outlined,
            title: 'Best Hydration Day',
            description: data.bestHydrationDay,
            color: theme.colorScheme.tertiary,
          ),
        ],
      ),
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
            'Loading analytics...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
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
              child: Icon(Icons.water_drop_outlined,
                  size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Start drinking water to see your analytics dashboard. Pull down to refresh.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
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
              child: Icon(Icons.analytics_outlined,
                  size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Setup Incomplete',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete onboarding to enable analytics.',
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

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load analytics',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
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