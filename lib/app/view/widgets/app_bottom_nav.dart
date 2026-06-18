import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    final route = switch (index) {
      0 => AppRoutes.dashboard,
      1 => AppRoutes.accounts,
      2 => AppRoutes.credits,
      3 => AppRoutes.profile,
      _ => AppRoutes.dashboard,
    };
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) => _go(context, i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Cuentas',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_card_outlined),
          selectedIcon: Icon(Icons.credit_card_rounded),
          label: 'Créditos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}
