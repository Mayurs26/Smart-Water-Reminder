import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/core/services/notification_service.dart';
import 'package:smart_water_reminder/providers/reminder_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, rp, _) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildStatusCard(context, rp),
                const SizedBox(height: 20),
                _buildMainToggle(context, rp),
                const SizedBox(height: 20),
                if (rp.remindersEnabled) ...[
                  _buildIntervalSection(context, rp),
                  const SizedBox(height: 20),
                  _buildTimeWindowSection(context, rp),
                  const SizedBox(height: 20),
                  _buildPendingSection(context),
                  const SizedBox(height: 20),
                ],
                _buildTipsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ReminderProvider rp) {
    final theme = Theme.of(context);
    final isEnabled = rp.remindersEnabled;
    final intervalLabel = AppConstants.intervalLabel(rp.reminderInterval);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHighest,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (isEnabled
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              size: 28,
              color: isEnabled
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Reminders Active' : 'Reminders Off',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isEnabled
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Every $intervalLabel · ${rp.reminderStartTime}–${rp.reminderEndTime}'
                      : 'Turn on reminders to stay hydrated',
                  style: TextStyle(
                    fontSize: 13,
                    color: isEnabled
                        ? Colors.white.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle(BuildContext context, ReminderProvider rp) {
    final theme = Theme.of(context);

    return _buildCard(
      context,
      child: SwitchListTile(
        value: rp.remindersEnabled,
        onChanged: (val) => rp.setRemindersEnabled(val),
        title: const Text(
          'Enable Water Reminders',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          rp.remindersEnabled
              ? "You'll receive regular reminders to drink water"
              : 'Tap to enable reminder notifications',
          style: theme.textTheme.bodySmall,
        ),
        secondary: Icon(
          Icons.notifications_outlined,
          color: rp.remindersEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildIntervalSection(BuildContext context, ReminderProvider rp) {
    final theme = Theme.of(context);
    // All presets in minutes — includes short values for device testing.
    final presets = AppConstants.reminderIntervalPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'REMINDER INTERVAL',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remind me every',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Two rows of 4 chips to fit all 8 presets
                _buildIntervalRow(context, rp, theme, presets.sublist(0, 4)),
                const SizedBox(height: 8),
                _buildIntervalRow(context, rp, theme, presets.sublist(4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '1–2 min intervals are for notification testing only.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalRow(BuildContext context, ReminderProvider rp,
      ThemeData theme, List<int> items) {
    return Row(
      children: items.map((mins) {
        final isSelected = rp.reminderInterval == mins;
        final label = AppConstants.intervalLabel(mins);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => rp.setReminderInterval(mins),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeWindowSection(BuildContext context, ReminderProvider rp) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'ACTIVE HOURS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send reminders between',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Wake Up',
                        time: rp.reminderStartTime,
                        icon: Icons.wb_sunny_outlined,
                        onChanged: (t) => rp.setReminderStartTime(t),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Expanded(
                      child: _TimePickerButton(
                        label: 'Sleep',
                        time: rp.reminderEndTime,
                        icon: Icons.bedtime_outlined,
                        onChanged: (t) => rp.setReminderEndTime(t),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingSection(BuildContext context) {
    final theme = Theme.of(context);

    return _buildCard(
      context,
      child: FutureBuilder<List<dynamic>>(
        future: NotificationService().getPendingNotifications(),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.alarm_outlined,
                size: 22,
                color: theme.colorScheme.primary,
              ),
            ),
            title: const Text(
              'Scheduled Reminders',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              snapshot.connectionState == ConnectionState.waiting
                  ? 'Loading...'
                  : '$count reminder${count == 1 ? '' : 's'} scheduled',
            ),
            trailing: snapshot.connectionState == ConnectionState.waiting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: count > 0
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    final theme = Theme.of(context);
    final tips = [
      ('💧', 'Drink water before each meal',
          'Helps with digestion and appetite control'),
      ('🌅', 'Start your morning with a glass',
          'Rehydrate after overnight sleep'),
      ('⏰', 'Set regular intervals',
          'Consistency leads to better hydration habits'),
      ('🥤', 'Keep a water bottle nearby',
          'Visible reminders increase water intake'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                'HYDRATION TIPS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildCard(
          context,
          child: Column(
            children: tips.asMap().entries.map((e) {
              final (emoji, title, subtitle) = e.value;
              final isLast = e.key == tips.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Text(emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        Text(subtitle, style: theme.textTheme.bodySmall),
                    dense: true,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 56,
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.12),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = time.split(':');
    final tod = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked =
              await showTimePicker(context: context, initialTime: tod);
          if (picked != null && context.mounted) {
            onChanged(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
