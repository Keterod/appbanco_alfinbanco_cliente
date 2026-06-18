import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/payment_schedule_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../model/credit_model.dart';
import '../../viewmodel/credits_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';
import '../widgets/app_bottom_nav.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  late final CreditsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreditsViewModel();
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _payInstallment() {
    Navigator.of(context).pushNamed(
      AppRoutes.transfers,
      arguments: 'pagoCredito',
    );
  }

  Color _statusColor(PaymentInstallmentStatus status) {
    return switch (status) {
      PaymentInstallmentStatus.paid => Colors.green.shade700,
      PaymentInstallmentStatus.pending => AppColors.secondary,
      PaymentInstallmentStatus.overdue => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlfinAppBar(title: 'Créditos'),
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

          final credit = vm.activeCredit;

          if (credit == null) {
            return _buildEmptyCredit(context);
          }

          return _buildContent(context, vm, credit);
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
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

  Widget _buildEmptyCredit(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.credit_card_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tienes créditos activos.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si tienes un crédito aprobado, aparecerá aquí.',
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

  Widget _buildContent(
      BuildContext context, CreditsViewModel vm, CreditModel credit) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.productName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  label: 'Monto pendiente',
                  value:
                      'S/ ${FormatUtils.formatSoles(credit.pendingAmount)}',
                  highlight: true,
                ),
                _MetricRow(
                  label: 'Cuota mensual',
                  value: vm.monthlyInstallment > 0
                      ? 'S/ ${FormatUtils.formatSoles(vm.monthlyInstallment)}'
                      : '—',
                ),
                _MetricRow(
                  label: 'Próximo pago',
                  value: FormatUtils.formatDate(credit.nextPaymentDate),
                ),
                _MetricRow(
                  label: 'TEA referencial',
                  value: vm.teaPercent > 0
                      ? '${vm.teaPercent.toStringAsFixed(1)} %'
                      : '—',
                ),
                const SizedBox(height: 16),
                if (vm.paymentProgress > 0) ...[
                  Text(
                    'Progreso de pago',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: vm.paymentProgress,
                      minHeight: 10,
                      backgroundColor: AppColors.grayLight,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(vm.paymentProgress * 100).toStringAsFixed(0)} % completado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _payInstallment,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Pagar cuota'),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Cronograma de pagos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (vm.schedule.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.schedule.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ScheduleTile(
                    item: vm.schedule[i],
                    statusColor: _statusColor(vm.schedule[i].status),
                  ),
                ],
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No hay cronograma disponible.',
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.secondary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.statusColor,
  });

  final PaymentScheduleModel item;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Text(
          '${item.installmentNumber}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: statusColor,
            fontSize: 13,
          ),
        ),
      ),
      title: Text('Cuota ${item.installmentNumber}'),
      subtitle: Text(
        'Vence: ${FormatUtils.formatDate(item.dueDate)} · '
        'S/ ${FormatUtils.formatSoles(item.amount)}',
      ),
      trailing: Chip(
        label: Text(
          item.statusLabel,
          style: const TextStyle(fontSize: 11, color: AppColors.white),
        ),
        backgroundColor: statusColor,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
