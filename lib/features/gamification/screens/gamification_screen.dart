import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_water_reminder/features/gamification/providers/gamification_provider.dart';
import 'package:smart_water_reminder/features/gamification/widgets/achievement_badge.dart';
import 'package:smart_water_reminder/features/gamification/widgets/daily_challenges.dart';
import 'package:smart_water_reminder/features/gamification/widgets/level_xp_card.dart';
import 'package:smart_water_reminder/features/gamification/widgets/streak_calendar.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, _) {
          if (provider.achievements.isEmpty) {
            return _buildLoadingState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger reload
            },
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
                        LevelXpCard(userLevel: provider.userLevel),
                        const SizedBox(height: 24),
                        StreakCalendar(streakData: provider.streakData),
                        const SizedBox(height: 24),
                        DailyChallengesWidget(
                          challenges: provider.dailyChallenges,
                          onChallengeUpdated: (challenge) {
                            // Update handled by provider
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildAchievementsSection(context, provider),
                      ],
                    ),
                  ),
                ),
              ],
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
          'Your Progress',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your level, streaks, and unlock achievements',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context, GamificationProvider provider) {
    final theme = Theme.of(context);
    final unlocked = provider.achievements.where((a) => a.isUnlocked).toList();
    final locked = provider.achievements.where((a) => !a.isUnlocked).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${unlocked.length}/${provider.achievements.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...unlocked.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AchievementBadge(achievement: a),
            )),
        if (locked.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Locked',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: locked.map((a) => SizedBox(
                  width: 150,
                  child: AchievementBadge(achievement: a),
                )).toList(),
          ),
        ],
      ],
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
            'Loading achievements...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}