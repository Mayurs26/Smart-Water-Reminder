import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_water_reminder/features/analytics/models/analytics_data.dart';

enum ChartPeriod { daily, weekly, monthly }

class IntakeChart extends StatefulWidget {
  final AnalyticsData data;
  final ChartPeriod period;
  final int dailyGoal;

  const IntakeChart({
    super.key,
    required this.data,
    required this.period,
    required this.dailyGoal,
  });

  @override
  State<IntakeChart> createState() => _IntakeChartState();
}

class _IntakeChartState extends State<IntakeChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(IntakeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _buildChart(context);
        },
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final spots = _getSpots();
    final maxY = _getMaxY();

    if (spots.isEmpty) {
      return _buildEmptyState(context);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: _getMaxX(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getYInterval(maxY),
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _getXInterval(),
              getTitlesWidget: (value, meta) => _getBottomTitle(value, meta),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: _getYInterval(maxY),
              getTitlesWidget: (value, meta) => _getLeftTitle(value, meta),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.8),
                primaryColor,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: primaryColor,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.3),
                  primaryColor.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_formatAmount(spot.y)} ml',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots() {
    switch (widget.period) {
      case ChartPeriod.daily:
        return _getDailySpots();
      case ChartPeriod.weekly:
        return widget.data.weeklyChartData;
      case ChartPeriod.monthly:
        return widget.data.monthlyChartData;
    }
  }

  List<FlSpot> _getDailySpots() {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    
    for (int hour = 0; hour < 24; hour++) {
      int amount = 0;
      
      for (final intake in widget.data.allIntakes) {
        if (intake.timestamp.hour == hour && 
            intake.timestamp.year == now.year &&
            intake.timestamp.month == now.month &&
            intake.timestamp.day == now.day) {
          amount += intake.amount;
        }
      }
      
      spots.add(FlSpot(hour.toDouble(), amount.toDouble()));
    }
    
    return spots;
  }

  double _getMaxX() {
    switch (widget.period) {
      case ChartPeriod.daily:
        return 23;
      case ChartPeriod.weekly:
        return 6;
      case ChartPeriod.monthly:
        final now = DateTime.now();
        return DateTime(now.year, now.month + 1, 0).day.toDouble() - 1;
    }
  }

  double _getMaxY() {
    double maxAmount = widget.dailyGoal.toDouble() * 1.2;
    
    for (final spot in _getSpots()) {
      if (spot.y > maxAmount) maxAmount = spot.y;
    }
    
    double result = (maxAmount / 100).ceil() * 100.0;
    return result > 0 ? result : 100.0;
  }

  double _getYInterval(double maxY) {
    if (maxY <= 200) return 50;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 2000) return 500;
    return 1000;
  }

  double _getXInterval() {
    switch (widget.period) {
      case ChartPeriod.daily:
        return 3;
      case ChartPeriod.weekly:
        return 1;
      case ChartPeriod.monthly:
        return 5;
    }
  }

  Widget _getBottomTitle(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    Widget text;
    switch (widget.period) {
      case ChartPeriod.daily:
        if (value.toInt() % 3 == 0) {
          text = Text('${value.toInt()}:00', style: style);
        } else {
          text = const Text('');
        }
        break;
      case ChartPeriod.weekly:
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        if (value.toInt() < days.length) {
          text = Text(days[value.toInt()], style: style);
        } else {
          text = const Text('');
        }
        break;
      case ChartPeriod.monthly:
        if (value.toInt() % 5 == 0 || value == 0) {
          text = Text('${value.toInt() + 1}', style: style);
        } else {
          text = const Text('');
        }
        break;
    }
    
    return SideTitleWidget(meta: meta, space: 4, child: text);
  }

  Widget _getLeftTitle(double value, TitleMeta meta) {
    if (value == 0) return const Text('');
    
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    
    String text;
    if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(1)}L';
    } else {
      text = '${value.toInt()}ml';
    }
    
    return SideTitleWidget(meta: meta, space: 4, child: Text(text, style: style));
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return (amount / 1000).toStringAsFixed(1);
    }
    return amount.toInt().toString();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking to see your analytics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}