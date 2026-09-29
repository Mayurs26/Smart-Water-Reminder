import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_water_reminder/features/onboarding/models/onboarding_data.dart';
import 'package:smart_water_reminder/features/onboarding/screens/finish_screen.dart';
import 'package:smart_water_reminder/features/onboarding/screens/personal_info_screen.dart';
import 'package:smart_water_reminder/features/onboarding/screens/reminder_setup_screen.dart'
    show ReminderSetupScreen;
import 'package:smart_water_reminder/features/onboarding/screens/water_goal_screen.dart';
import 'package:smart_water_reminder/features/onboarding/screens/welcome_screen.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingData _data = OnboardingData();
  int _currentPage = 0;

  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.saveUserSettings(_data.toUserSettings());
    
    if (mounted) {
      // Navigation will be handled by the Consumer in main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        WelcomeScreen(onNext: _nextPage),
        PersonalInfoScreen(
          data: _data,
          onNext: _nextPage,
          onPrevious: _previousPage,
        ),
        WaterGoalScreen(
          data: _data,
          onNext: _nextPage,
          onPrevious: _previousPage,
        ),
        ReminderSetupScreen(
          data: _data,
          onNext: _nextPage,
          onPrevious: _previousPage,
        ),
        FinishScreen(
          data: _data,
          onComplete: _completeOnboarding,
        ),
      ],
    );
  }
}