import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_water_reminder/core/services/notification_service.dart';
import 'package:smart_water_reminder/data/models/user_settings.dart';
import 'package:smart_water_reminder/providers/reminder_provider.dart';
import 'package:smart_water_reminder/providers/theme_provider.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';
import 'package:smart_water_reminder/features/gamification/providers/gamification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final settings = userProvider.userSettings;
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _buildHeader(context, settings),
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Profile',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildProfileTile(context, settings, userProvider),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'Hydration Goal',
                icon: Icons.flag_outlined,
                children: [
                  _buildGoalTile(context, settings, userProvider),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'Appearance',
                icon: Icons.palette_outlined,
                children: [
                  _buildThemeTile(context),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                children: [
                  _buildRemindersTile(context, settings, userProvider),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                title: 'Data',
                icon: Icons.storage_outlined,
                children: [
                  _buildDataTile(context),
                ],
              ),
              const SizedBox(height: 24),
              _buildAppInfo(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserSettings settings) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                settings.name?.isNotEmpty == true
                    ? settings.name![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.dailyGoal} ml daily goal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (settings.weight != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${settings.weight!.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    UserSettings settings,
    UserProvider userProvider,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
      title: const Text('Edit Profile'),
      subtitle: Text(
        settings.name ?? 'Set your name',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showEditProfileDialog(context, settings, userProvider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildGoalTile(
    BuildContext context,
    UserSettings settings,
    UserProvider userProvider,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary),
      title: const Text('Daily Water Goal'),
      subtitle: Text('${settings.dailyGoal} ml per day'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showEditGoalDialog(context, settings, userProvider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildThemeTile(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return ListTile(
          leading: Icon(
            themeProvider.themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : themeProvider.themeMode == ThemeMode.light
                    ? Icons.light_mode_outlined
                    : Icons.brightness_auto_outlined,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Theme'),
          subtitle: Text(_themeModeLabel(themeProvider.themeMode)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showThemeDialog(context, themeProvider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  Widget _buildRemindersTile(
    BuildContext context,
    UserSettings settings,
    UserProvider userProvider,
  ) {
    final theme = Theme.of(context);
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, _) {
        return ListTile(
          leading: Icon(
            reminderProvider.remindersEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: reminderProvider.remindersEnabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: const Text('Smart Reminders'),
          subtitle: Text(
            reminderProvider.remindersEnabled
                ? 'Every ${reminderProvider.reminderInterval}h • ${reminderProvider.reminderStartTime} - ${reminderProvider.reminderEndTime}'
                : 'Disabled',
          ),
          trailing: Switch(
            value: reminderProvider.remindersEnabled,
            onChanged: (val) => reminderProvider.setRemindersEnabled(val),
          ),
          onTap: () => _showRemindersDialog(context, reminderProvider, settings),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  Widget _buildDataTile(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.bar_chart_outlined, color: theme.colorScheme.primary),
          title: const Text('Pending Notifications'),
          subtitle: const Text('View scheduled reminders'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showPendingNotifications(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 56,
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        ListTile(
          leading: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
          title: Text(
            'Reset All Data',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: const Text('Delete all water intake history'),
          trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.error),
          onTap: () => _showResetConfirmation(context),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          Icon(Icons.water_drop_rounded, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            'Smart Water Reminder',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stay hydrated, stay healthy 💧',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    UserSettings settings,
    UserProvider userProvider,
  ) {
    final nameController = TextEditingController(text: settings.name ?? '');
    final weightController = TextEditingController(
      text: settings.weight?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: settings.age?.toString() ?? '',
    );
    String? selectedGender = settings.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) {
                  setStateDialog(() {
                    selectedGender = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newSettings = settings.copyWith(
                  name: nameController.text.trim().isEmpty
                      ? settings.name
                      : nameController.text.trim(),
                  weight: double.tryParse(weightController.text),
                  age: int.tryParse(ageController.text),
                  gender: selectedGender,
                );
                userProvider.updateUserSettings(newSettings);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalDialog(
    BuildContext context,
    UserSettings settings,
    UserProvider userProvider,
  ) {
    int goal = settings.dailyGoal;
    final goals = [1500, 2000, 2500, 3000, 3500, 4000];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Daily Water Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$goal ml',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: goal.toDouble(),
                min: 1000,
                max: 5000,
                divisions: 80,
                label: '$goal ml',
                onChanged: (val) => setStateDialog(() => goal = val.round()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: goals.map((g) => ActionChip(
                  label: Text('${g}ml'),
                  onPressed: () => setStateDialog(() => goal = g),
                  backgroundColor: goal == g
                      ? Theme.of(ctx).colorScheme.primaryContainer
                      : null,
                )).toList(),
              ),
              if (settings.weight != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Suggested based on weight: ${settings.suggestedDailyGoal} ml',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                userProvider.updateUserSettings(settings.copyWith(dailyGoal: goal));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            final labels = ['System', 'Light', 'Dark'];
            final icons = [
              Icons.brightness_auto_outlined,
              Icons.light_mode_outlined,
              Icons.dark_mode_outlined,
            ];
            return ListTile(
              leading: Icon(icons[mode.index]),
              title: Text(labels[mode.index]),
              // ignore: deprecated_member_use
              trailing: Radio<ThemeMode>(
                value: mode,
                // ignore: deprecated_member_use
                groupValue: themeProvider.themeMode,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) themeProvider.setThemeMode(val);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                themeProvider.setThemeMode(mode);
                Navigator.pop(ctx);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRemindersDialog(
    BuildContext context,
    ReminderProvider reminderProvider,
    UserSettings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RemindersBottomSheet(
        reminderProvider: reminderProvider,
        settings: settings,
      ),
    );
  }

  void _showPendingNotifications(BuildContext context) async {
    final ns = NotificationService();
    final pending = await ns.getPendingNotifications();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${pending.length} Scheduled Reminders'),
        content: pending.isEmpty
            ? const Text('No reminders are currently scheduled.')
            : SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: pending.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(pending[i].title ?? 'Reminder'),
                    subtitle: Text('ID: ${pending[i].id}'),
                    dense: true,
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will permanently delete all your water intake history and reset your progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // 1. Close dialog
              Navigator.pop(ctx);
              
              if (!context.mounted) return;

              // 2. Clear Notifications
              await NotificationService().cancelAllReminders();

              if (!context.mounted) return;

              // 3. Clear SharedPreferences completely
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              
              if (!context.mounted) return;

              // 4. Clear all providers
              context.read<GamificationProvider>().resetAllData();
              await context.read<WaterProvider>().clearAllData();
              
              if (!context.mounted) return;
              // 5. Finally, clear UserProvider (which sets isOnboarded to false and triggers navigation to Onboarding)
              await context.read<UserProvider>().clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _RemindersBottomSheet extends StatefulWidget {
  final ReminderProvider reminderProvider;
  final UserSettings settings;

  const _RemindersBottomSheet({
    required this.reminderProvider,
    required this.settings,
  });

  @override
  State<_RemindersBottomSheet> createState() => _RemindersBottomSheetState();
}

class _RemindersBottomSheetState extends State<_RemindersBottomSheet> {
  late bool _enabled;
  late int _interval;
  late String _startTime;
  late String _endTime;

  final _intervals = [1, 2, 3, 4, 6];

  @override
  void initState() {
    super.initState();
    _enabled = widget.reminderProvider.remindersEnabled;
    _interval = widget.reminderProvider.reminderInterval;
    _startTime = widget.reminderProvider.reminderStartTime;
    _endTime = widget.reminderProvider.reminderEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reminder Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _enabled,
            onChanged: (val) => setState(() => _enabled = val),
            title: const Text('Enable Reminders'),
            subtitle: const Text('Get notified to drink water regularly'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surface,
          ),
          const SizedBox(height: 16),
          if (_enabled) ...[
            Text(
              'Reminder Interval',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _intervals.map((h) => ChoiceChip(
                label: Text('${h}h'),
                selected: _interval == h,
                onSelected: (_) => setState(() => _interval = h),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    context,
                    label: 'Start Time',
                    time: _startTime,
                    onChanged: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(
                    context,
                    label: 'End Time',
                    time: _endTime,
                    onChanged: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveSettings,
              child: const Text('Save Reminder Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required String time,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final parts = time.split(':');
    final tod = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: tod,
        );
        if (picked != null) {
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final rp = widget.reminderProvider;
    await rp.setRemindersEnabled(_enabled);
    if (_enabled) {
      await rp.setReminderInterval(_interval);
      await rp.setReminderStartTime(_startTime);
      await rp.setReminderEndTime(_endTime);
    }
    if (mounted) Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder settings saved')),
      );
    }
  }
}
