import 'package:flutter/material.dart';

import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../viewmodel/home_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final HomeViewModel _viewModel;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      setState(() => _bottomIndex = 0);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 1
              ? 'Cuentas disponibles próximamente.'
              : index == 2
                  ? 'Créditos en detalle próximamente.'
                  : 'Perfil próximamente.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  String _formatDate(DateTime d) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    final acc = vm.savingsAccount;
    final cr = vm.activeCredit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Inicio'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purpleSupport,
                AppColors.secondary,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'Hola, ${vm.clientName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Resumen de tus productos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 24),
          _BalanceCard(
            title: acc.accountType,
            subtitle: acc.accountNumber,
            amountLabel: 'S/ ${HomeViewModel.formatSoles(acc.balance)}',
            accent: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _BalanceCard(
            title: cr.productName,
            subtitle: 'Próximo pago: ${_formatDate(cr.nextPaymentDate)}',
            amountLabel: 'Pendiente S/ ${HomeViewModel.formatSoles(cr.pendingAmount)}',
            accent: AppColors.secondary,
          ),
          const SizedBox(height: 28),
          Text(
            'Últimos movimientos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.recentMovements.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MovementTile(item: vm.recentMovements[i]),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: _onTabTapped,
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
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.55),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      amountLabel,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.item});

  final MovementItem item;

  @override
  Widget build(BuildContext context) {
    final prefix = item.amount >= 0 ? '+' : '';
    final color = item.amount >= 0 ? AppColors.secondary : AppColors.textDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        item.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(item.dateLabel),
      trailing: Text(
        '$prefix S/ ${HomeViewModel.formatSoles(item.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
