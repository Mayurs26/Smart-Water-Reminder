import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/core/services/smart_reminder_engine.dart';
import 'package:smart_water_reminder/core/theme/app_theme.dart';
import 'package:smart_water_reminder/core/utils/date_utils.dart' as date_utils;
import 'package:smart_water_reminder/features/gamification/providers/gamification_provider.dart';
import 'package:smart_water_reminder/features/gamification/widgets/goal_celebration.dart';
import 'package:smart_water_reminder/features/gamification/widgets/level_xp_card.dart';
import 'package:smart_water_reminder/features/home/widgets/quick_add_buttons.dart';
import 'package:smart_water_reminder/features/home/widgets/stats_row.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';
import 'package:smart_water_reminder/providers/reminder_provider.dart';
import 'package:smart_water_reminder/features/history/screens/history_screen.dart';
import 'package:smart_water_reminder/features/reminders/screens/reminders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _bubbleController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _heroController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (!mounted) return;
    final waterProvider = context.read<WaterProvider>();
    final userProvider = context.read<UserProvider>();
    waterProvider.setCurrentDate(date_utils.AppDateUtils.getTodayString());
    waterProvider.loadDailyTotals();
    if (userProvider.userSettings != null) waterProvider.loadTodayData();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    if (h < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer3<UserProvider, WaterProvider, GamificationProvider>(
        builder: (context, userProvider, waterProvider, gamProv, _) {
          // Still loading initial data
          if (userProvider.isLoading) {
            return _buildLoadingState(context);
          }

          final settings = userProvider.userSettings;
          if (settings == null) return _buildErrorState(context);

          final dailyGoal  = settings.dailyGoal;
          final consumed   = waterProvider.totalConsumed;
          final remaining  = waterProvider.getRemaining(dailyGoal);
          final progress   = waterProvider.getProgress(dailyGoal);
          final glassCount = waterProvider.glassCount;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => waterProvider.loadTodayData(),
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    _buildSliverAppBar(context, settings.name),
                    SliverToBoxAdapter(
                      child: SlideTransition(
                        position: _heroSlide,
                        child: FadeTransition(
                          opacity: _heroFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Hero hydration card
                                _HeroHydrationCard(
                                  consumed: consumed,
                                  goal: dailyGoal,
                                  remaining: remaining,
                                  progress: progress,
                                  glassCount: glassCount,
                                  bubbleController: _bubbleController,
                                ),
                                const SizedBox(height: 16),
                                // ── XP level card
                                LevelXpCard(userLevel: gamProv.userLevel),
                                const SizedBox(height: 16),
                                // ── Quick add buttons
                                QuickAddButtons(
                                  onAddWater: (amount) {
                                    HapticFeedback.mediumImpact();
                                    waterProvider.addWaterIntake(amount);
                                    gamProv.onWaterAdded(
                                        amount, dailyGoal, consumed + amount);
                                  },
                                  isLoading: waterProvider.isLoading,
                                ),
                                const SizedBox(height: 16),
                                // ── Smart reminder card
                                Consumer<ReminderProvider>(
                                  builder: (context, reminderProv, _) {
                                    return _SmartReminderCard(
                                      todayIntakes: waterProvider.todayIntakes,
                                      dailyGoal: dailyGoal,
                                      consumed: consumed,
                                      intervalMinutes: reminderProv.reminderInterval,
                                      endTimeStr: reminderProv.reminderEndTime,
                                      remindersEnabled: reminderProv.remindersEnabled,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // ── Stats row
                                StatsRow(
                                  glassCount: glassCount,
                                  lastIntake: waterProvider.lastAddedIntake,
                                  onUndo: waterProvider.canUndo
                                      ? () => waterProvider.undoLastIntake()
                                      : null,
                                  canUndo: waterProvider.canUndo,
                                  onIntakesTodayTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => _IntakeTodayDetailSheet(
                                        waterProvider: waterProvider,
                                        dailyGoal: dailyGoal,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GoalCelebrationOverlay(
                show: gamProv.showGoalCelebration,
                currentStreak: gamProv.streakData.currentStreak,
                leveledUp: gamProv.justLeveledUp,
                newLevel: gamProv.newLevel,
                newAchievements: gamProv.newlyUnlockedAchievements,
                onDismiss: gamProv.dismissCelebration,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Sliver app bar ────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context, String? userName) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remindersEnabled = context.watch<ReminderProvider>().remindersEnabled;

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 80,
      collapsedHeight: 60,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.primary,
      flexibleSpace: LayoutBuilder(
        builder: (ctx, constraints) {
          final ratio = ((constraints.maxHeight - 60) / 20).clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 100, 12),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ratio > 0.4)
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                Text(
                  userName?.isNotEmpty == true ? userName! : 'There',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded,
              color: theme.colorScheme.onSurfaceVariant, size: 22),
          tooltip: 'History',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  remindersEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: remindersEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                tooltip: 'Reminders',
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen())),
              ),
              if (remindersEnabled)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: theme.colorScheme.primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text('Loading your data…', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Could not load data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _initializeData, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  HERO HYDRATION CARD — Fixed layout
// ══════════════════════════════════════════════════════════════════════
class _HeroHydrationCard extends StatefulWidget {
  final int consumed;
  final int goal;
  final int remaining;
  final double progress;
  final int glassCount;
  final AnimationController bubbleController;

  const _HeroHydrationCard({
    required this.consumed,
    required this.goal,
    required this.remaining,
    required this.progress,
    required this.glassCount,
    required this.bubbleController,
  });

  @override
  State<_HeroHydrationCard> createState() => _HeroHydrationCardState();
}

class _HeroHydrationCardState extends State<_HeroHydrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    // Animate from 0 → current progress on first build
    _ringAnim = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));
    _ringController.forward();
  }

  @override
  void didUpdateWidget(_HeroHydrationCard old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      // Animate from old progress → new progress
      _ringAnim = Tween<double>(begin: old.progress, end: widget.progress)
          .animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic));
      _ringController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = (widget.progress * 100).clamp(0, 100).round();
    final bool goalMet = widget.progress >= 1.0;

    final List<Color> cardGradient = isDark
        ? [const Color(0xFF082541), const Color(0xFF0C3358), const Color(0xFF0D4060)]
        : [const Color(0xFF0EA5E9), const Color(0xFF06B6D4), const Color(0xFF0891B2)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                .withValues(alpha: isDark ? 0.25 : 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Wave fill animation — needs explicit SizedBox to get size ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: widget.bubbleController,
                builder: (ctx, _) => CustomPaint(
                  painter: _WavePainter(
                    progress: widget.progress,
                    waveOffset: widget.bubbleController.value,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
            // ── Floating bubbles ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: widget.bubbleController,
                builder: (ctx, _) {
                  final t = widget.bubbleController.value;
                  return LayoutBuilder(builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        _bubble(w * 0.82, h * (0.1 + t * 0.05), 80, 0.07),
                        _bubble(w * 0.05, h * (0.65 + t * 0.06), 50, 0.06),
                        _bubble(w * 0.65, h * (0.78 + t * 0.04), 30, 0.08),
                        _bubble(w * 0.15, h * (0.2 - t * 0.03).clamp(0.05, 0.4), 20, 0.06),
                      ],
                    );
                  });
                },
              ),
            ),
            // ── Card content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Hydration",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date_utils.AppDateUtils.formatDisplayDate(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (goalMet)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🎉 Goal Met!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Progress ring ──
                  AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (ctx, _) {
                      final animProg = _ringAnim.value.clamp(0.0, 1.0);
                      return SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Track ring
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 10,
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.white.withValues(alpha: 0.12)),
                              ),
                            ),
                            // Progress arc
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: animProg,
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                                valueColor: AlwaysStoppedAnimation(
                                  goalMet
                                      ? const Color(0xFF34D399)
                                      : Colors.white,
                                ),
                              ),
                            ),
                            // Center text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.consumed}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    height: 1,
                                  ),
                                ),
                                const Text(
                                  'ml',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Stat pills ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatPill(
                          icon: Icons.flag_rounded,
                          label: 'Goal',
                          value: '${widget.goal} ml'),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.15)),
                      _StatPill(
                          icon: Icons.water_drop_rounded,
                          label: 'Left',
                          value: '${widget.remaining} ml'),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.15)),
                      _StatPill(
                          icon: Icons.local_drink_rounded,
                          label: 'Glasses',
                          value: '${widget.glassCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double x, double y, double size, double opacity) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 17),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Wave painter ─────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double progress;
  final double waveOffset;
  final bool isDark;

  _WavePainter({
    required this.progress,
    required this.waveOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.width <= 0 || size.height <= 0) return;
    final fillHeight = size.height * (1 - progress.clamp(0.0, 0.92));
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.05 : 0.09)
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, fillHeight);
    for (double x = 0; x <= size.width; x += 1) {
      final y = fillHeight +
          math.sin((x / size.width * 2 * math.pi) + waveOffset * 2 * math.pi) * 6 +
          math.sin((x / size.width * 4 * math.pi) + waveOffset * 2 * math.pi * 1.5) * 3;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.waveOffset != waveOffset;
}

// ══════════════════════════════════════════════════════════════════════
//  SMART REMINDER CARD
//  Shows: Last Drink · Next Drink · Recommended amount · Live Countdown
// ══════════════════════════════════════════════════════════════════════
class _SmartReminderCard extends StatefulWidget {
  final List todayIntakes;
  final int dailyGoal;
  final int consumed;
  final int intervalMinutes;
  final String endTimeStr;
  final bool remindersEnabled;

  const _SmartReminderCard({
    required this.todayIntakes,
    required this.dailyGoal,
    required this.consumed,
    required this.intervalMinutes,
    required this.endTimeStr,
    required this.remindersEnabled,
  });

  @override
  State<_SmartReminderCard> createState() => _SmartReminderCardState();
}

class _SmartReminderCardState extends State<_SmartReminderCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalMet = widget.consumed >= widget.dailyGoal;

    final lastDrinkTime = SmartReminderEngine.lastIntakeTime(
      List.from(widget.todayIntakes),
    );

    final nextTime = SmartReminderEngine.nextReminderTime(
      todayIntakes: List.from(widget.todayIntakes),
      intervalMinutes: widget.intervalMinutes,
      endTimeStr: widget.endTimeStr,
    );

    final recommended = SmartReminderEngine.recommendedAmount(
      dailyGoal: widget.dailyGoal,
      consumed: widget.consumed,
      intervalMinutes: widget.intervalMinutes,
      endTimeStr: widget.endTimeStr,
    );

    final diff = nextTime.difference(_now);
    final totalMins = diff.inMinutes.clamp(0, 24 * 60);
    final displaySecs = (diff.inSeconds.clamp(0, 24 * 3600) % 60);

    final primaryColor = theme.colorScheme.primary;
    final cardColor = isDark
        ? theme.colorScheme.surface
        : theme.colorScheme.surfaceContainerLowest;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: goalMet
          ? _GoalMetRow(theme: theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(Icons.notifications_active_outlined,
                          size: 18, color: primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Smart Reminder',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 13, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '${totalMins}m ${displaySecs.toString().padLeft(2, '0')}s',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ReminderInfoCell(
                      icon: Icons.access_time_rounded,
                      label: 'Last drink',
                      value: lastDrinkTime != null
                          ? date_utils.AppDateUtils.formatTime(lastDrinkTime)
                          : '—',
                      color: theme.colorScheme.secondary,
                      theme: theme,
                    ),
                    _vDivider(theme),
                    _ReminderInfoCell(
                      icon: Icons.schedule_rounded,
                      label: 'Next drink',
                      value: date_utils.AppDateUtils.formatTime(nextTime),
                      color: primaryColor,
                      theme: theme,
                    ),
                    _vDivider(theme),
                    _ReminderInfoCell(
                      icon: Icons.water_drop_rounded,
                      label: 'Recommended',
                      value: '$recommended ml',
                      color: const Color(0xFF06B6D4),
                      theme: theme,
                    ),
                  ],
                ),
                if (!widget.remindersEnabled) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Reminders off — enable in settings',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _vDivider(ThemeData theme) => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: theme.colorScheme.outline.withValues(alpha: 0.15),
      );
}

class _ReminderInfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _ReminderInfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GoalMetRow extends StatelessWidget {
  final ThemeData theme;

  const _GoalMetRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Daily goal complete 🎉 Great job today!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  INTAKE TODAY DETAIL SHEET
// ══════════════════════════════════════════════════════════════════════
class _IntakeTodayDetailSheet extends StatelessWidget {
  final WaterProvider waterProvider;
  final int dailyGoal;

  const _IntakeTodayDetailSheet({
    required this.waterProvider,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consumed = waterProvider.totalConsumed;
    final remaining = (dailyGoal - consumed).clamp(0, dailyGoal);
    final progress = waterProvider.getProgress(dailyGoal);
    final intakes = waterProvider.todayIntakes;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Intake',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '$consumed ml / $dailyGoal ml',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              'Remaining: $remaining ml',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          Expanded(
            child: intakes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop_outlined, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No water recorded yet today', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: intakes.length,
                    separatorBuilder: (context, index) => Divider(height: 1, indent: 56, color: theme.colorScheme.outline.withValues(alpha: 0.05)),
                    itemBuilder: (context, index) {
                      final intake = intakes[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.water_drop, size: 20, color: theme.colorScheme.primary),
                        ),
                        title: Text('${intake.amount} ml', style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          date_utils.AppDateUtils.formatTime(intake.timestamp),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
          ),
          
          // Next Drink prediction
          Consumer<ReminderProvider>(
            builder: (context, rp, _) {
              if (consumed >= dailyGoal || intakes.isEmpty || !rp.remindersEnabled) {
                return const SizedBox.shrink();
              }
              
              final nextTime = SmartReminderEngine.nextReminderTime(
                todayIntakes: intakes,
                intervalMinutes: rp.reminderInterval,
                endTimeStr: rp.reminderEndTime,
              );
              
              final recommended = SmartReminderEngine.recommendedAmount(
                dailyGoal: dailyGoal,
                consumed: consumed,
                intervalMinutes: rp.reminderInterval,
                endTimeStr: rp.reminderEndTime,
              );
              
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.access_time_filled, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NEXT DRINK', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(date_utils.AppDateUtils.formatTime(nextTime), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Suggested', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('$recommended ml', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}