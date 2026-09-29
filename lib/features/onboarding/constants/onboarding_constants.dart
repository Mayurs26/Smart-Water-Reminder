import 'package:flutter/material.dart';

class OnboardingConstants {
  static const List<OnboardingStep> steps = [
    OnboardingStep(
      index: 0,
      title: 'Welcome',
      subtitle: 'Let\'s set up your hydration journey',
      icon: Icons.water_drop_outlined,
    ),
    OnboardingStep(
      index: 1,
      title: 'About You',
      subtitle: 'Help us personalize your experience',
      icon: Icons.person_outline,
    ),
    OnboardingStep(
      index: 2,
      title: 'Daily Goal',
      subtitle: 'Set your water intake target',
      icon: Icons.flag_outlined,
    ),
    OnboardingStep(
      index: 3,
      title: 'Reminders',
      subtitle: 'Stay on track with smart notifications',
      icon: Icons.notifications_outlined,
    ),
    OnboardingStep(
      index: 4,
      title: 'All Set!',
      subtitle: 'You\'re ready to start hydrating',
      icon: Icons.check_circle_outline,
    ),
  ];

  static const List<int> reminderIntervals = [1, 2, 3, 4];
  static const double minWeight = 30.0;
  static const double maxWeight = 200.0;
  static const int minAge = 10;
  static const int maxAge = 100;
  static const int minDailyGoal = 500;
  static const int maxDailyGoal = 5000;
  static const int goalStep = 50;
}

class OnboardingStep {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const OnboardingStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}