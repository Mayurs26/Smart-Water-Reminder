import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_water_reminder/features/onboarding/models/onboarding_data.dart';
import 'package:smart_water_reminder/features/onboarding/widgets/onboarding_layout.dart';

class PersonalInfoScreen extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const PersonalInfoScreen({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  final List<_ActivityOption> _activityOptions = const [
    _ActivityOption('light', '🚶', 'Light', 'Desk job, mostly sitting'),
    _ActivityOption('moderate', '🚴', 'Moderate', 'Some daily movement'),
    _ActivityOption('high', '🏋️', 'Active', 'Regular workouts'),
    _ActivityOption('intense', '🔥', 'Intense', 'Daily intense training'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.data.name;
    if (widget.data.age != null) _ageController.text = widget.data.age.toString();
    if (widget.data.weight != null) {
      _weightController.text = widget.data.weight!.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    if (_formKey.currentState!.validate()) {
      if (widget.data.gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender')),
        );
        return;
      }
      widget.data.name = _nameController.text.trim();
      widget.data.age = int.tryParse(_ageController.text);
      final newWeight = double.tryParse(_weightController.text);
      widget.data.weight = newWeight;
      // Auto-calculate goal based on weight + activity
      if (newWeight != null && newWeight > 0) {
        widget.data.dailyGoal = widget.data.suggestedDailyGoal;
      }
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      currentStep: 1,
      onNext: _validateAndProceed,
      onPrevious: widget.onPrevious,
      isNextEnabled: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildSectionLabel(context, 'Your Name'),
            const SizedBox(height: 8),
            _buildNameField(context),
            const SizedBox(height: 20),
            _buildSectionLabel(context, 'Gender'),
            const SizedBox(height: 10),
            _buildGenderSelector(context),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel(context, 'Weight'),
                    const SizedBox(height: 8),
                    _buildWeightField(context),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel(context, 'Age (optional)'),
                    const SizedBox(height: 8),
                    _buildAgeField(context),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(context, 'Activity Level'),
            const SizedBox(height: 10),
            _buildActivitySelector(context),
            const SizedBox(height: 16),
            _buildGoalPreviewCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector(BuildContext context) {
    final theme = Theme.of(context);
    final options = ['Male', 'Female', 'Other'];
    return Row(
      children: options.map((opt) {
        final isSelected = widget.data.gender == opt;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: opt == options.last ? 0 : 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  widget.data.gender = opt;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    opt,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.primary
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'e.g. Alex',
        prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Name required';
        if (v.trim().length < 2) return 'Too short';
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildWeightField(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}'))],
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: '70',
        suffixText: 'kg',
        prefixIcon: Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final w = double.tryParse(v);
        if (w == null || w < 30 || w > 250) return '30–250 kg';
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildAgeField(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: '25',
        suffixText: 'yrs',
        prefixIcon: Icon(Icons.cake_outlined, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        if (v != null && v.isNotEmpty) {
          final a = int.tryParse(v);
          if (a == null || a < 10 || a > 100) return '10–100';
        }
        return null;
      },
    );
  }

  Widget _buildActivitySelector(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: _activityOptions.map((opt) {
        final isSelected = widget.data.activityLevel == opt.value;
        return GestureDetector(
          onTap: () {
            setState(() {
              widget.data.activityLevel = opt.value;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(opt.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        opt.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        opt.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalPreviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 30) return const SizedBox.shrink();

    int base = (weight * 35).round();
    if (widget.data.activityLevel == 'high' || widget.data.activityLevel == 'intense') {
      base += 500;
    }
    final suggested = base < 2200 ? 2200 : base;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.secondary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_drink_rounded,
                color: theme.colorScheme.onPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your personalised goal',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$suggested ml / day',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'AUTO',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityOption {
  final String value;
  final String emoji;
  final String label;
  final String description;

  const _ActivityOption(this.value, this.emoji, this.label, this.description);
}