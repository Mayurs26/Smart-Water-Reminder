import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';

/// Pure computation — no Flutter/state dependencies.
/// Calculates next reminder time, countdown, and recommended amount
/// from the actual intake history and user settings.
class SmartReminderEngine {
  const SmartReminderEngine._();

  // ──────────────────────────────────────────────────────────────────────────
  //  Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// The DateTime of the last intake today, or null if nothing logged yet.
  static DateTime? lastIntakeTime(List<WaterIntake> todayIntakes) {
    if (todayIntakes.isEmpty) return null;
    // intakes are stored newest-first; first element is most recent.
    return todayIntakes.first.timestamp;
  }

  /// The next reminder DateTime.
  ///
  /// Logic:
  ///   – If there is a last intake, next = lastIntake + intervalHours.
  ///   – If there is no intake yet, next = now + intervalHours (first reminder).
  ///   – If the calculated time is already in the past, next = now + interval
  ///     (i.e., the reminder fires as soon as possible — still in the future).
  static DateTime nextReminderTime({
    required List<WaterIntake> todayIntakes,
    required int intervalHours,
    required String endTimeStr,
  }) {
    final now = DateTime.now();
    final base = lastIntakeTime(todayIntakes) ?? now;
    final candidate = base.add(Duration(hours: intervalHours));

    // If the candidate is already past, next opportunity is from now.
    final next = candidate.isBefore(now)
        ? now.add(Duration(hours: intervalHours))
        : candidate;

    // Cap at sleep time.
    final end = _todayAt(endTimeStr);
    return next.isBefore(end) ? next : end;
  }

  /// Countdown in minutes from now to the next reminder (≥ 0).
  static int countdownMinutes({
    required List<WaterIntake> todayIntakes,
    required int intervalHours,
    required String endTimeStr,
  }) {
    final next = nextReminderTime(
      todayIntakes: todayIntakes,
      intervalHours: intervalHours,
      endTimeStr: endTimeStr,
    );
    final diff = next.difference(DateTime.now()).inMinutes;
    return diff.clamp(0, 24 * 60);
  }

  /// How many reminder slots remain from now until end of day.
  static int remainingSlots({
    required int intervalHours,
    required String endTimeStr,
  }) {
    final now = DateTime.now();
    final end = _todayAt(endTimeStr);
    if (end.isBefore(now)) return 0;
    final minutes = end.difference(now).inMinutes;
    final slots = (minutes / (intervalHours * 60)).ceil();
    return slots.clamp(1, 100); // at least 1 slot so we never divide by zero
  }

  /// Recommended amount for the *next* drink.
  ///
  /// Formula:  remaining ml ÷ remaining reminder slots.
  /// Rounded to nearest 50 ml, clamped to [50, 800].
  /// Returns 0 when goal is already met.
  static int recommendedAmount({
    required int dailyGoal,
    required int consumed,
    required int intervalHours,
    required String endTimeStr,
  }) {
    final remaining = (dailyGoal - consumed).clamp(0, dailyGoal);
    if (remaining == 0) return 0;

    final slots = remainingSlots(
      intervalHours: intervalHours,
      endTimeStr: endTimeStr,
    );

    final raw = (remaining / slots).ceil();
    // Round to nearest 50 ml for readability.
    final rounded = ((raw / 50).round() * 50).clamp(50, 800);
    return rounded;
  }

  /// Default interval hours when not configured.
  static int get defaultIntervalHours => AppConstants.defaultReminderInterval;

  // ──────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────────────────

  static DateTime _todayAt(String timeStr) {
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 22;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }
}
