import 'package:flutter/material.dart';
import 'package:smart_water_reminder/features/onboarding/models/onboarding_data.dart';
import 'package:smart_water_reminder/features/onboarding/widgets/onboarding_layout.dart';

class ReminderSetupScreen extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const ReminderSetupScreen({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  late TimeOfDay _wakeUpTime;
  late TimeOfDay _sleepTime;

  @override
  void initState() {
    super.initState();
    _wakeUpTime = widget.data.wakeUpTime;
    _sleepTime = widget.data.sleepTime;
  }

  Future<void> _selectTime(bool isWakeUp) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _sleepTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _sleepTime = picked;
        }
      });
    }
  }

  String _fmtAmPm(TimeOfDay t) => t.format(context);

  // Dynamic interval based on goal and awake hours
  int get _computedInterval {
    final wakeMin = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    final sleepMin = _sleepTime.hour * 60 + _sleepTime.minute;
    final awakeMin = sleepMin > wakeMin ? sleepMin - wakeMin : 900;
    final drinks = (widget.data.dailyGoal / 250).ceil();
    if (drinks <= 0) return 120;
    final intervalMin = awakeMin ~/ drinks;
    return intervalMin.clamp(30, 240);
  }

  List<String> get _previewTimes {
    final wakeMin = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    final sleepMin = _sleepTime.hour * 60 + _sleepTime.minute;
    if (sleepMin <= wakeMin) return [];

    final interval = _computedInterval;
    final times = <String>[];
    int cur = wakeMin;
    while (cur <= sleepMin && times.length < 8) {
      final h = (cur ~/ 60).toString().padLeft(2, '0');
      final m = (cur % 60).toString().padLeft(2, '0');
      times.add('$h:$m');
      cur += interval;
    }
    return times;
  }

  int get _awakeHours {
    final wakeMin = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    final sleepMin = _sleepTime.hour * 60 + _sleepTime.minute;
    return sleepMin > wakeMin ? ((sleepMin - wakeMin) / 60).round() : 15;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 3,
      onNext: () {
        widget.data.wakeUpTime = _wakeUpTime;
        widget.data.sleepTime = _sleepTime;
        widget.data.reminderInterval = (_computedInterval / 60).ceil().clamp(1, 4);
        widget.onNext();
      },
      onPrevious: widget.onPrevious,
      child: Column(
        children: [
          const SizedBox(height: 4),
          _buildToggleCard(context),
          const SizedBox(height: 16),
          if (widget.data.remindersEnabled) ...[
            _buildTimePickers(context),
            const SizedBox(height: 16),
            _buildSmartScheduleCard(context),
            const SizedBox(height: 16),
            _buildPreviewCard(context),
          ] else
            _buildDisabledCard(context),
        ],
      ),
    );
  }

  Widget _buildToggleCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.data.remindersEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: widget.data.remindersEnabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.data.remindersEnabled
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.data.remindersEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: widget.data.remindersEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Reminders',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Adaptive notifications based on your schedule',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.data.remindersEnabled,
            onChanged: (v) => setState(() => widget.data.remindersEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickers(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeCard(
            context,
            icon: '☀️',
            label: 'Wake Up',
            time: _fmtAmPm(_wakeUpTime),
            color: const Color(0xFFFFC107),
            onTap: () => _selectTime(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimeCard(
            context,
            icon: '🌙',
            label: 'Sleep',
            time: _fmtAmPm(_sleepTime),
            color: const Color(0xFF5C6BC0),
            onTap: () => _selectTime(false),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String time,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Icon(Icons.edit_rounded, size: 14, color: color.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartScheduleCard(BuildContext context) {
    final theme = Theme.of(context);
    final drinks = (widget.data.dailyGoal / 250).ceil();
    final intervalMin = _computedInterval;
    final intervalLabel = intervalMin >= 60
        ? '${(intervalMin / 60).toStringAsFixed(0)} hr ${intervalMin % 60 == 0 ? '' : '${intervalMin % 60} min'}'.trim()
        : '$intervalMin min';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Smart Schedule',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildScheduleStat(context, '⏰', '$_awakeHours hrs', 'Awake window'),
          const SizedBox(height: 6),
          _buildScheduleStat(context, '🥤', '$drinks glasses', 'Goal glasses'),
          const SizedBox(height: 6),
          _buildScheduleStat(context, '🔔', intervalLabel, 'Reminder interval'),
        ],
      ),
    );
  }

  Widget _buildScheduleStat(BuildContext context, String emoji, String value, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final times = _previewTimes;
    if (times.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s reminder preview',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...times.map((t) => _buildTimePill(context, t, theme.colorScheme.primary)),
            if (times.length >= 8)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+ more', style: theme.textTheme.labelSmall),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePill(BuildContext context, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDisabledCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_off_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Reminders Disabled',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You can always enable them later in Settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}