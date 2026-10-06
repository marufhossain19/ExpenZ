import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'services/supabase_service.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/search_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/notification_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/main_shell.dart';
import 'screens/limit_settings_screen.dart';
import 'screens/alert_history_screen.dart';
import 'core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize Supabase
  if (AppConfig.isSupabaseEnabled) {
    await SupabaseService.init();
  }

  // Create shared SupabaseService instance
  final supabaseService = SupabaseService();

  runApp(ExpenseTrackerApp(
    hiveService: hiveService,
    supabaseService: supabaseService,
  ));
}

/// Root application widget with all providers configured.
class ExpenseTrackerApp extends StatelessWidget {
  final HiveService hiveService;
  final SupabaseService supabaseService;

  const ExpenseTrackerApp({
    super.key,
    required this.hiveService,
    required this.supabaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose HiveService so screens can open/close user-scoped boxes
        Provider<HiveService>.value(value: hiveService),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(hiveService)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => ExpenseProvider(hiveService, supabaseService)),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
            create: (_) => BudgetProvider(hiveService, supabaseService)),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider(hiveService, supabaseService)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Expense Tracker AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (_) => const SplashScreen(),
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/forgot_password': (_) => const ForgotPasswordScreen(),
              '/main': (_) => const MainShell(),
              '/limit_settings': (_) => const LimitSettingsScreen(),
              '/alert_history': (_) => const AlertHistoryScreen(),
            },
          );
        },
      ),
    );
  }
}
