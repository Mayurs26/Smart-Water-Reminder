import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_water_reminder/core/theme/app_theme.dart';
import 'package:smart_water_reminder/features/analytics/screens/analytics_screen.dart';
import 'package:smart_water_reminder/features/gamification/screens/gamification_screen.dart';
import 'package:smart_water_reminder/features/home/screens/home_screen.dart';
import 'package:smart_water_reminder/features/history/screens/history_screen.dart';
import 'package:smart_water_reminder/features/onboarding/screens/onboarding_screen.dart';
import 'package:smart_water_reminder/features/reminders/screens/reminders_screen.dart';
import 'package:smart_water_reminder/features/settings/screens/settings_screen.dart';
import 'package:smart_water_reminder/features/splash/screens/splash_screen.dart';
import 'package:smart_water_reminder/providers/theme_provider.dart';
import 'package:smart_water_reminder/providers/user_provider.dart';
import 'package:smart_water_reminder/providers/water_provider.dart';
import 'package:smart_water_reminder/providers/reminder_provider.dart';
import 'package:smart_water_reminder/features/gamification/providers/gamification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadThemeMode()),
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUserSettings()),
        ChangeNotifierProvider(create: (_) => WaterProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider(prefs)),
        ChangeNotifierProxyProvider2<UserProvider, WaterProvider, ReminderProvider>(
          create: (context) => ReminderProvider(prefs)..initialize(),
          update: (_, userProvider, waterProvider, reminderProvider) {
            reminderProvider!.setDependencies(userProvider, waterProvider);
            return reminderProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Smart Water Reminder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(next: AppEntryPoint()),
          );
        },
      ),
    );
  }
}

class AppEntryPoint extends StatelessWidget {
  const AppEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          // Return a scaffold that matches the background color to avoid flashing
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        }

        if (!userProvider.isOnboarded) {
          return const OnboardingScreen();
        }

        // Initialize water provider callback when app is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WaterProvider>().setOnWaterChanged((consumed) {
            context.read<ReminderProvider>().checkAndRescheduleIfGoalMet();
          });
        });

        return const MainNavigationScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const GamificationScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      endDrawer: NavigationDrawer(
        selectedIndex: _currentIndex == 3 ? 2 : null,
        onDestinationSelected: (index) {
          Navigator.pop(context); // Close drawer
          
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
          } else if (index == 2) {
            setState(() => _currentIndex = 3); // Go to Settings tab
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Menu',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.history_outlined),
            label: Text('History'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.notifications_outlined),
            label: Text('Reminders'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Divider(),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            label: Text('Settings'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Achievements',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}