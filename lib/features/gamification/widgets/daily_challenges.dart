import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/gamification/models/achievement.dart';

class DailyChallengesWidget extends StatelessWidget {
  final List<DailyChallenge> challenges;
  final Function(DailyChallenge) onChallengeUpdated;

  const DailyChallengesWidget({
    super.key,
    required this.challenges,
    required this.onChallengeUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Challenges',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_completedCount/${challenges.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...challenges.map((challenge) => _ChallengeTile(
                challenge: challenge,
                onUpdate: onChallengeUpdated,
              )),
        ],
      ),
    );
  }

  int get _completedCount => challenges.where((c) => c.isCompleted).length;
}

class _ChallengeTile extends StatefulWidget {
  final DailyChallenge challenge;
  final Function(DailyChallenge) onUpdate;

  const _ChallengeTile({
    required this.challenge,
    required this.onUpdate,
  });

  @override
  State<_ChallengeTile> createState() => _ChallengeTileState();
}

class _ChallengeTileState extends State<_ChallengeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.challenge.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ChallengeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge.progress != widget.challenge.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.challenge.progress,
        end: widget.challenge.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
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
    final challenge = widget.challenge;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: challenge.isCompleted
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: challenge.isCompleted
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: challenge.isCompleted
                      ? theme.colorScheme.primary
                      : _getChallengeColor(challenge.type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getChallengeIcon(challenge.type),
                  color: challenge.isCompleted
                      ? theme.colorScheme.onPrimary
                      : _getChallengeColor(challenge.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: challenge.isCompleted
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (challenge.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outlined,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Done',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          challenge.isCompleted
                              ? Colors.green
                              : _getChallengeColor(challenge.type),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(challenge.progress * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '+${challenge.xpReward} XP',
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
              if (!challenge.isCompleted)
                IconButton(
                  onPressed: () {
                    // Allow manual progress for testing
                    widget.onUpdate(challenge.copyWith(
                      currentProgress: challenge.targetValue,
                    ));
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'Complete (test)',
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.drinkAmount:
        return Colors.blue;
      case ChallengeType.earlyDrink:
        return Colors.amber;
      case ChallengeType.customGoal:
        return Colors.purple;
      case ChallengeType.streakMaintain:
        return Colors.orange;
      case ChallengeType.noReminders:
        return Colors.teal;
    }
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.drinkAmount:
        return Icons.flag_outlined;
      case ChallengeType.earlyDrink:
        return Icons.wb_sunny_outlined;
      case ChallengeType.customGoal:
        return Icons.rocket_launch_outlined;
      case ChallengeType.streakMaintain:
        return Icons.local_fire_department_outlined;
      case ChallengeType.noReminders:
        return Icons.notifications_off_outlined;
    }
  }
}