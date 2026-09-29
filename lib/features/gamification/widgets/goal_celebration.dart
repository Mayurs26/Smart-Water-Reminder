import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/gamification/models/achievement.dart';

class GoalCelebrationOverlay extends StatefulWidget {
  final bool show;
  final int currentStreak;
  final bool leveledUp;
  final int newLevel;
  final List<Achievement> newAchievements;
  final VoidCallback onDismiss;

  const GoalCelebrationOverlay({
    super.key,
    required this.show,
    required this.currentStreak,
    this.leveledUp = false,
    this.newLevel = 0,
    this.newAchievements = const [],
    required this.onDismiss,
  });

  @override
  State<GoalCelebrationOverlay> createState() => _GoalCelebrationOverlayState();
}

class _GoalCelebrationOverlayState extends State<GoalCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    if (widget.show) {
      _controller.forward();
      _particleController.repeat();
    }
  }

  @override
  void didUpdateWidget(GoalCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.show && widget.show) {
      _controller.forward(from: 0);
      _particleController.repeat();
    } else if (oldWidget.show && !widget.show) {
      _controller.reverse();
      _particleController.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _particleController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.black.withValues(alpha: 0.7 * _fadeAnimation.value),
            child: Stack(
              children: [
                // Particles
                ...List.generate(20, (index) => _buildParticle(index)),
                // Main celebration card
                Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildCelebrationCard(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final size = MediaQuery.of(context).size;
    final progress = _particleController.value;
    final angle = (index * 18.0) * math.pi / 180.0;
    final radius = 100.0 * progress;
    final dx = radius * progress * 3 * math.cos(angle);
    final dy = -radius * progress * 3 * math.sin(angle);
    final opacity = (1.0 - progress) * 0.8;

    return Positioned(
      left: size.width / 2 + dx,
      top: size.height / 2 + dy,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: progress * 4 * math.pi,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.8),
                  Colors.purple.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Icon(
                widget.leveledUp ? Icons.military_tech_outlined : Icons.check_circle_outlined,
                size: 50,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            widget.leveledUp ? 'Level Up!' : 'Goal Completed!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            widget.leveledUp
                ? 'Congratulations! You reached Level ${widget.newLevel}!'
                : 'Amazing! ${widget.currentStreak} day streak!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // New achievements
          if (widget.newAchievements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New Achievement${widget.newAchievements.length > 1 ? 's' : ''}!',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: widget.newAchievements.map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: a.rarityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: a.rarityColor.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(a.icon, size: 16, color: a.rarityColor),
                              const SizedBox(width: 6),
                              Text(
                                a.title,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: a.rarityColor,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          // Continue button
          FilledButton(
            onPressed: widget.onDismiss,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Continue',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}