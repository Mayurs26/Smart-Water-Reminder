import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/onboarding/widgets/onboarding_layout.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onNext;

  const WelcomeScreen({super.key, required this.onNext});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnims = List.generate(4, (i) {
      final start = i * 0.18;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOut),
        ),
      );
    });
    _slideAnims = List.generate(4, (i) {
      final start = i * 0.18;
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.4).clamp(0, 1), curve: Curves.easeOutCubic),
        ),
      );
    });
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 0,
      onNext: widget.onNext,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildFeature(context, 0,
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF2196F3),
            gradientColors: [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
            title: 'Smart Hydration Tracking',
            description: 'Log water instantly with one tap. Custom amounts, quick presets, and real-time progress rings.',
          ),
          const SizedBox(height: 14),
          _buildFeature(context, 1,
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF00BCD4),
            gradientColors: [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
            title: 'Dynamic Smart Reminders',
            description: 'Reminders adapt to your schedule, meals, and activity level — not just a fixed timer.',
          ),
          const SizedBox(height: 14),
          _buildFeature(context, 2,
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF4CAF50),
            gradientColors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
            title: 'Analytics & Streaks',
            description: 'Track weekly trends, daily streaks, and unlock achievements as you build healthy habits.',
          ),
          const SizedBox(height: 14),
          _buildOfflineCard(context, 3),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeature(BuildContext context, int index, {
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(
        position: _slideAnims[index],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '100% Private & Offline',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All data stays on your device. No accounts, no cloud.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}