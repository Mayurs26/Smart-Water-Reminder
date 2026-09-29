import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/gamification/models/achievement.dart';

class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final bool showLocked;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.onTap,
    this.showLocked = true,
  });

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    if (widget.achievement.isUnlocked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.achievement.isUnlocked && widget.achievement.isUnlocked) {
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
    final achievement = widget.achievement;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: achievement.isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        achievement.rarityColor.withValues(alpha: 0.2),
                        achievement.rarityColor.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: achievement.isUnlocked
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: achievement.isUnlocked
                    ? achievement.rarityColor.withValues(alpha: 0.5)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: achievement.rarityColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: achievement.isUnlocked
                            ? LinearGradient(
                                colors: [
                                  achievement.rarityColor.withValues(alpha: 0.3),
                                  achievement.rarityColor,
                                ],
                              )
                            : null,
                        color: achievement.isUnlocked
                            ? null
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        border: Border.all(
                          color: achievement.isUnlocked
                              ? achievement.rarityColor
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        achievement.icon,
                        size: 36,
                        color: achievement.isUnlocked
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    if (!achievement.isUnlocked && widget.showLocked)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (achievement.isUnlocked)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: achievement.rarityColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: achievement.isUnlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: achievement.isUnlocked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: achievement.rarityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        achievement.rarityLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: achievement.rarityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.stars_outlined,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${achievement.xpReward}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}