import 'package:flutter/material.dart';

import '../view/auth/login_screen.dart';
import '../view/home/dashboard_screen.dart';
import '../ui/theme/app_theme.dart';
import 'app_routes.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfin Banco',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
      },
    );
  }
}
