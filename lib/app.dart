import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:giyas_ai/core/providers/auth_provider.dart';
import 'package:giyas_ai/features/auth/login_screen.dart';
import 'package:giyas_ai/features/chat/enhanced_chat_screen.dart';
import 'package:giyas_ai/features/mood_analysis/voice_mood_screen.dart';
import 'package:giyas_ai/features/daily_plan/daily_plan_screen.dart';
import 'package:giyas_ai/features/weekly_planner/weekly_planner_screen.dart';
import 'package:giyas_ai/features/settings/settings_screen.dart';
import 'package:giyas_ai/l10n/l10n.dart';

class GiyasAIApp extends ConsumerWidget {
  const GiyasAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Giyas.AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Blue-600
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: authState.when(
        data: (user) => user != null ? const MainApp() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).refreshProfile();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DailyPlanScreen(),
    const WeeklyPlannerScreen(),
    const EnhancedChatScreen(),
    const VoiceMoodScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.grey[600],
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex == 0
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.calendar_today, size: 24),
                  ),
                  label: l10n.dailyPlan,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex == 1
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.calendar_month, size: 24),
                  ),
                  label: l10n.weeklyPlan,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex == 2
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 24),
                  ),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex == 3
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.psychology_outlined, size: 24),
                  ),
                  label: 'Mood',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentIndex == 4
                          ? const Color(0xFF2563EB).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: const Icon(Icons.settings_outlined, size: 24),
                  ),
                  label: l10n.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
