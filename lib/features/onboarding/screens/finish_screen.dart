import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/onboarding/models/onboarding_data.dart';
import 'package:smart_water_reminder/features/onboarding/widgets/onboarding_layout.dart';

class FinishScreen extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onComplete;

  const FinishScreen({
    super.key,
    required this.data,
    required this.onComplete,
  });

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _checkAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drinks = (widget.data.dailyGoal / 250).ceil();

    return OnboardingLayout(
      currentStep: 4,
      onNext: widget.onComplete,
      isLastStep: true,
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Celebration circle
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: _checkAnim.value,
                      child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _fadeAnim,
            builder: (context, _) => Opacity(
              opacity: _fadeAnim.value,
              child: Column(
                children: [
                  Text(
                    widget.data.name.isNotEmpty
                        ? '${_wave(widget.data.name)} You\'re all set!'
                        : '🎉 You\'re all set!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your hydration journey starts now. We\'ll keep you on track every day.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildSummaryCard(context,
                  icon: Icons.local_drink_rounded,
                  label: 'Daily Target',
                  value: '${widget.data.dailyGoal} ml',
                  accent: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(context,
                  icon: Icons.wine_bar_rounded,
                  label: 'Glasses per day',
                  value: '$drinks glasses of 250ml',
                  accent: const Color(0xFF00BCD4),
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(context,
                  icon: Icons.notifications_active_rounded,
                  label: 'Smart Reminders',
                  value: widget.data.remindersEnabled
                      ? '${widget.data.wakeUpTime.format(context)} – ${widget.data.sleepTime.format(context)}'
                      : 'Disabled',
                  accent: widget.data.remindersEnabled
                      ? const Color(0xFF4CAF50)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (widget.data.weight != null) ...[
                  const SizedBox(height: 10),
                  _buildSummaryCard(context,
                    icon: Icons.monitor_weight_rounded,
                    label: 'Based on your weight',
                    value: '${widget.data.weight!.toStringAsFixed(1)} kg · ${widget.data.activityLevel} activity',
                    accent: const Color(0xFF9C27B0),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _wave(String name) {
    final firstName = name.trim().split(' ').first;
    return 'Hi $firstName! 👋';
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: accent, size: 18),
        ],
      ),
    );
  }
}