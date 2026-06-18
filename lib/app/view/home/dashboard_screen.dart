import 'package:flutter/material.dart';

import '../../model/movement_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/home_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';
import '../widgets/app_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final HomeViewModel _viewModel;

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

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    final acc = vm.savingsAccount;
    final cr = vm.activeCredit;

    return Scaffold(
      appBar: AlfinAppBar(
        title: 'Inicio',
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.login),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.transfers),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Transferencias y Pagos'),
            ),
          ),
          const SizedBox(height: 16),
          _BalanceCard(
            title: 'Mis solicitudes',
            subtitle: 'Revisa el estado de tus solicitudes de crédito',
            amountLabel: '',
            accent: AppColors.purpleSupport,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.requests),
          ),
          const SizedBox(height: 24),
          _BalanceCard(
            title: acc.accountType,
            subtitle: acc.accountNumber,
            amountLabel: 'S/ ${FormatUtils.formatSoles(acc.balance)}',
            accent: AppColors.primary,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.accounts),
          ),
          const SizedBox(height: 16),
          _BalanceCard(
            title: cr.productName,
            subtitle:
                'Próximo pago: ${FormatUtils.formatDate(cr.nextPaymentDate)}',
            amountLabel:
                'Pendiente S/ ${FormatUtils.formatSoles(cr.pendingAmount)}',
            accent: AppColors.secondary,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.credits),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: accent.withValues(alpha: 0.8),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.textDark.withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        amountLabel,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
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
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.item});

  final MovementModel item;

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
        '$prefix S/ ${FormatUtils.formatSoles(item.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
