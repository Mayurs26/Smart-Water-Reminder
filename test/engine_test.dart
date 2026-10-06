import 'package:flutter_test/flutter_test.dart';
import 'package:smart_water_reminder/core/constants/app_constants.dart';
import 'package:smart_water_reminder/core/services/smart_reminder_engine.dart';
import 'package:smart_water_reminder/data/models/water_intake.dart';

void main() {
  group('AppConstants', () {
    test('intervalLabel formats correctly', () {
      expect(AppConstants.intervalLabel(1), '1m');
      expect(AppConstants.intervalLabel(45), '45m');
      expect(AppConstants.intervalLabel(60), '1h');
      expect(AppConstants.intervalLabel(90), '1h 30m');
      expect(AppConstants.intervalLabel(120), '2h');
    });
  });

  group('SmartReminderEngine', () {
    test('lastIntakeTime returns null for empty list', () {
      expect(SmartReminderEngine.lastIntakeTime([]), isNull);
    });

    test('lastIntakeTime returns first item (newest)', () {
      final t1 = DateTime(2023, 1, 1, 10, 0);
      final t2 = DateTime(2023, 1, 1, 11, 0);
      final intakes = [
        WaterIntake(amount: 200, timestamp: t2, date: '2023-01-01'), // Newest first
        WaterIntake(amount: 200, timestamp: t1, date: '2023-01-01'),
      ];
      expect(SmartReminderEngine.lastIntakeTime(intakes), t2);
    });

    test('remainingSlots clamps to 1 minimum', () {
      // Very close to end time
      final slots = SmartReminderEngine.remainingSlots(
        intervalMinutes: 60,
        endTimeStr: '00:00', // effectively in the past
      );
      expect(slots, greaterThanOrEqualTo(1));
    });

    test('recommendedAmount logic', () {
      // remaining = 1500, slots = 5 => 300 ml
      int rec = SmartReminderEngine.recommendedAmount(
        dailyGoal: 2500,
        consumed: 1000,
        intervalMinutes: 60,
        endTimeStr: '23:59', 
      );
      expect(rec, greaterThan(0));
      // Actual slots will depend on current time, but let's test goal met:
      int met = SmartReminderEngine.recommendedAmount(
        dailyGoal: 2000,
        consumed: 2000,
        intervalMinutes: 60,
        endTimeStr: '23:59',
      );
      expect(met, 0);

      int exceeded = SmartReminderEngine.recommendedAmount(
        dailyGoal: 2000,
        consumed: 2500,
        intervalMinutes: 60,
        endTimeStr: '23:59',
      );
      expect(exceeded, 0);
    });
  });
}
