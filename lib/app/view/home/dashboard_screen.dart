import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
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
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _viewModel.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlfinAppBar(
        title: 'Inicio',
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.loadError != null && !vm.usingSupabaseData) {
            return _buildError(context, vm);
          }

          return _buildContent(context, vm);
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildError(BuildContext context, HomeViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              vm.loadError ?? 'Error de conexión',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _viewModel.reload(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeViewModel vm) {
    final acc = vm.savingsAccount;
    final cr = vm.activeCredit;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Hola, ${vm.clientName.isNotEmpty ? vm.clientName : "Cliente"}',
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
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.requests),
        ),
        const SizedBox(height: 12),
        _BalanceCard(
          title: 'Mis operaciones',
          subtitle: 'Revisa tus transferencias y pagos realizados',
          amountLabel: '',
          accent: AppColors.purpleSupport,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.operations),
        ),
        const SizedBox(height: 24),
        if (acc != null)
          _BalanceCard(
            title: acc.accountType,
            subtitle: acc.accountNumber,
            amountLabel: 'S/ ${FormatUtils.formatSoles(acc.balance)}',
            accent: AppColors.primary,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.accounts),
          )
        else
          _EmptyCard(
            title: 'Cuenta de ahorros',
            message: 'No tienes cuentas registradas.',
            accent: AppColors.primary,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.accounts),
          ),
        const SizedBox(height: 16),
        if (cr != null)
          _BalanceCard(
            title: cr.productName,
            subtitle:
                'Próximo pago: ${FormatUtils.formatDate(cr.nextPaymentDate)}',
            amountLabel:
                'Pendiente S/ ${FormatUtils.formatSoles(cr.pendingAmount)}',
            accent: AppColors.secondary,
            onTap: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.credits),
          )
        else
          _EmptyCard(
            title: 'Crédito',
            message: 'No tienes créditos activos.',
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
        if (vm.recentMovements.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.recentMovements.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MovementTile(item: vm.recentMovements[i]),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No tienes movimientos recientes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ),
      ],
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
                      if (amountLabel.isNotEmpty) ...[
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.message,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String message;
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
              Container(width: 5, color: accent.withValues(alpha: 0.3)),
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
                              color: accent.withValues(alpha: 0.4),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.textDark.withValues(alpha: 0.4),
                              fontStyle: FontStyle.italic,
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
