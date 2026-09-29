import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/onboarding/constants/onboarding_constants.dart';
import 'package:smart_water_reminder/features/onboarding/models/onboarding_data.dart';
import 'package:smart_water_reminder/features/onboarding/widgets/onboarding_layout.dart';

class WaterGoalScreen extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const WaterGoalScreen({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<WaterGoalScreen> createState() => _WaterGoalScreenState();
}

class _WaterGoalScreenState extends State<WaterGoalScreen>
    with SingleTickerProviderStateMixin {
  late int _currentGoal;
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  final List<int> _presets = [1500, 2000, 2500, 3000, 3500, 4000];

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.data.dailyGoal;
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ringAnim = CurvedAnimation(parent: _ringController, curve: Curves.easeOut);
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _setGoal(int goal) {
    setState(() => _currentGoal = goal);
    _ringController.reset();
    _ringController.forward();
  }

  int get _suggestedGoal => widget.data.suggestedDailyGoal;
  bool get _isAutoCalc => _currentGoal == _suggestedGoal;

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 2,
      onNext: () {
        widget.data.dailyGoal = _currentGoal;
        widget.onNext();
      },
      onPrevious: widget.onPrevious,
      child: Column(
        children: [
          const SizedBox(height: 4),
          _buildRingDisplay(context),
          const SizedBox(height: 24),
          _buildPresets(context),
          const SizedBox(height: 20),
          _buildSlider(context),
          const SizedBox(height: 16),
          _buildTip(context),
        ],
      ),
    );
  }

  Widget _buildRingDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentGoal / OnboardingConstants.maxDailyGoal).clamp(0.0, 1.0);
    final drinks = (_currentGoal / 250).ceil();

    return Column(
      children: [
        AnimatedBuilder(
          animation: _ringAnim,
          builder: (context, child) {
            return SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 14,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  // Animated progress ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress * _ringAnim.value,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(
                        _isAutoCalc
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_currentGoal',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'ml / day',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        // Pills row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPill(
              context,
              icon: _isAutoCalc ? Icons.auto_awesome_rounded : Icons.edit_rounded,
              label: _isAutoCalc ? 'Auto-calculated' : 'Custom',
              color: _isAutoCalc ? theme.colorScheme.primary : theme.colorScheme.secondary,
            ),
            const SizedBox(width: 10),
            _buildPill(
              context,
              icon: Icons.local_drink_rounded,
              label: '$drinks glasses',
              color: const Color(0xFF00BCD4),
            ),
          ],
        ),
        if (_isAutoCalc && widget.data.weight != null) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.data.weight!.toStringAsFixed(1)} kg × 35 ml'
            '${widget.data.activityLevel == 'high' || widget.data.activityLevel == 'intense' ? ' + 500 ml activity' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPill(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(BuildContext context) {
    final theme = Theme.of(context);
    final allGoals = {..._presets, if (_suggestedGoal > 0) _suggestedGoal}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Select',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            if (_suggestedGoal > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⭐ ${_suggestedGoal}ml = your goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allGoals.map((g) {
            final isSelected = _currentGoal == g;
            final isRecommended = g == _suggestedGoal;
            return GestureDetector(
              onTap: () => _setGoal(g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isRecommended
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.outline.withValues(alpha: 0.25),
                    width: isSelected || isRecommended ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )]
                      : null,
                ),
                child: Text(
                  isRecommended ? '⭐ ${g}ml' : '${g}ml',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : isRecommended
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fine-tune', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              '$_currentGoal ml',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.15),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            value: _currentGoal.toDouble(),
            min: OnboardingConstants.minDailyGoal.toDouble(),
            max: OnboardingConstants.maxDailyGoal.toDouble(),
            divisions: ((OnboardingConstants.maxDailyGoal - OnboardingConstants.minDailyGoal) / 100).round(),
            onChanged: (v) => _setGoal(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${OnboardingConstants.minDailyGoal} ml',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('${OnboardingConstants.maxDailyGoal} ml',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  Widget _buildTip(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00BCD4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00BCD4).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Spread intake across the day. Your body absorbs water better in smaller, frequent amounts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}