import 'package:flutter/material.dart';

import '../view/accounts/accounts_screen.dart';
import '../view/auth/login_screen.dart';
import '../view/auth/register_screen.dart';
import '../view/credits/credits_screen.dart';
import '../view/home/dashboard_screen.dart';
import '../view/profile/profile_screen.dart';
import '../view/requests/requests_screen.dart';
import '../view/splash/splash_screen.dart';
import '../view/transfers/transfers_screen.dart';
import '../ui/theme/app_theme.dart';
import '../viewmodel/transfers_viewmodel.dart';
import 'app_routes.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfin Banco',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.accounts: (_) => const AccountsScreen(),
        AppRoutes.credits: (_) => const CreditsScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.requests: (_) => const RequestsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.transfers) {
          TransferOperationType? type;
          if (settings.arguments == 'pagoCredito') {
            type = TransferOperationType.pagoCredito;
          }
          return MaterialPageRoute<void>(
            builder: (_) => TransfersScreen(initialOperationType: type),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
