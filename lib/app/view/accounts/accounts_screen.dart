import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/movement_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../model/account_model.dart';
import '../../viewmodel/accounts_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';
import '../widgets/app_bottom_nav.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AccountsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AccountsViewModel();
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showStatementSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estado de cuenta disponible en modo demostración'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlfinAppBar(title: 'Cuentas'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.loadError != null && !vm.usingSupabaseData) {
            return _buildError(context);
          }

          if (vm.accounts.isEmpty) {
            return _buildEmptyAccount(context);
          }

          return _buildContent(context, vm);
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No se pudieron cargar los datos.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAccount(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tienes cuentas registradas.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las cuentas asociadas a tu perfil aparecerán aquí.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.4),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AccountsViewModel vm) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        for (var i = 0; i < vm.accounts.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _AccountCard(account: vm.accounts[i]),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showStatementSnackBar,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Ver estado de cuenta'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.transfers),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Transferir'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Últimos depósitos y retiros',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (vm.recentMovements.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.recentMovements.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MovementTile(movement: vm.recentMovements[i]),
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final bal = account.availableBalance ?? account.balance;
    final contable = account.accountingBalance ?? account.balance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.accountType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (account.isPrincipal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Principal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Número de cuenta',
              value: account.accountNumber,
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'CCI', value: account.cci ?? '—'),
            const Divider(height: 28),
            _InfoRow(
              label: 'Saldo disponible',
              value: 'S/ ${FormatUtils.formatSoles(bal)}',
              valueStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Saldo contable',
              value: 'S/ ${FormatUtils.formatSoles(contable)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: valueStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final MovementModel movement;

  @override
  Widget build(BuildContext context) {
    final prefix = movement.amount >= 0 ? '+' : '';
    final color =
        movement.amount >= 0 ? AppColors.secondary : AppColors.textDark;
    return ListTile(
      title: Text(movement.description),
      subtitle: Text('${movement.dateLabel} · ${movement.category}'),
      trailing: Text(
        '$prefix S/ ${FormatUtils.formatSoles(movement.amount)}',
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
