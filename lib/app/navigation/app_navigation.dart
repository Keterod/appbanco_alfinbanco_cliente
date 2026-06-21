import 'package:flutter/material.dart';

import '../model/credit_model.dart';
import '../model/operation_model.dart';
import '../model/request_model.dart';
import '../view/accounts/accounts_screen.dart';
import '../view/auth/login_screen.dart';
import '../view/auth/register_screen.dart';
import '../view/credits/credit_payment_screen.dart';
import '../view/credits/credits_screen.dart';
import '../view/home/dashboard_screen.dart';
import '../view/operations/operation_detail_screen.dart';
import '../view/operations/operations_screen.dart';
import '../view/profile/profile_screen.dart';
import '../view/loan_request/client_loan_request_screen.dart';
import '../view/requests/request_detail_screen.dart';
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
        AppRoutes.operations: (_) => const OperationsScreen(),
        AppRoutes.clientLoanRequest: (_) => const ClientLoanRequestScreen(),
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
        if (settings.name == AppRoutes.requestDetail) {
          final request = settings.arguments as RequestModel;
          return MaterialPageRoute<void>(
            builder: (_) => RequestDetailScreen(request: request),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.operationDetail) {
          final operation = settings.arguments as OperationModel;
          return MaterialPageRoute<void>(
            builder: (_) => OperationDetailScreen(operation: operation),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.creditPayment) {
          final credit = settings.arguments as CreditModel;
          return MaterialPageRoute<void>(
            builder: (_) => CreditPaymentScreen(credit: credit),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
