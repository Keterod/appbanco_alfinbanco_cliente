import 'package:flutter/material.dart';

import '../../model/account_model.dart';
import '../../model/credit_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/credit_payment_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';

class CreditPaymentScreen extends StatefulWidget {
  const CreditPaymentScreen({super.key, required this.credit});

  final CreditModel credit;

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  late final CreditPaymentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreditPaymentViewModel();
    _viewModel.loadData(widget.credit);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar pago'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogRow('Crédito', _viewModel.credit!.productName),
                const SizedBox(height: 6),
                _dialogRow(
                  'Cuota',
                  'Cuota ${_viewModel.nextInstallment!.installmentNumber}',
                ),
                const SizedBox(height: 6),
                _dialogRow(
                  'Cuenta origen',
                  '${_viewModel.selectedAccount!.accountType} · ${_viewModel.selectedAccount!.accountNumber}',
                ),
                const SizedBox(height: 6),
                _dialogRow(
                  'Monto',
                  'S/ ${FormatUtils.formatSoles(_viewModel.nextInstallment!.amount)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sí, pagar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textDark.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlfinAppBar(title: 'Pagar cuota'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.paymentResult != null) {
            return _buildSuccess(context, vm);
          }

          return _buildPaymentForm(context, vm);
        },
      ),
    );
  }

  Widget _buildSuccess(
      BuildContext context, CreditPaymentViewModel vm) {
    final result = vm.paymentResult!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      children: [
        Icon(Icons.check_circle_rounded,
            size: 80, color: Colors.green.shade600),
        const SizedBox(height: 24),
        Text(
          'Pago registrado correctamente',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _successRow(
                  context,
                  'N° de operación',
                  result.numeroOperacion,
                ),
                const Divider(height: 20),
                _successRow(
                  context,
                  'Fecha',
                  FormatUtils.formatDate(DateTime.now()),
                ),
                const Divider(height: 20),
                _successRow(
                  context,
                  'Cuota pagada',
                  'Cuota ${result.numeroCuota}',
                ),
                const Divider(height: 20),
                _successRow(
                  context,
                  'Monto',
                  'S/ ${FormatUtils.formatSoles(result.montoPagado)}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.credits),
            icon: const Icon(Icons.credit_card_outlined, size: 18),
            label: const Text('Ver créditos'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.operations),
            icon: const Icon(Icons.receipt_outlined, size: 18),
            label: const Text('Ver operaciones'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _successRow(
      BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textDark.withValues(alpha: 0.6),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(
      BuildContext context, CreditPaymentViewModel vm) {
    final credit = vm.credit!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.productName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Monto pendiente',
                  'S/ ${FormatUtils.formatSoles(credit.pendingAmount)}',
                  highlight: true,
                ),
                _infoRow(
                  'Cuota mensual',
                  credit.monthlyInstallment != null
                      ? 'S/ ${FormatUtils.formatSoles(credit.monthlyInstallment!)}'
                      : '—',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (vm.nextInstallment != null) ...[
          Text(
            'Siguiente cuota',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
            Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(
                    'N° de cuota',
                    '${vm.nextInstallment!.installmentNumber}',
                  ),
                  _infoRow(
                    'Fecha de vencimiento',
                    FormatUtils.formatDate(vm.nextInstallment!.dueDate),
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    'Monto',
                    'S/ ${FormatUtils.formatSoles(vm.nextInstallment!.amount)}',
                    highlight: true,
                  ),
                  if (vm.nextInstallment!.capital != null)
                    _infoRow(
                      'Capital',
                      'S/ ${FormatUtils.formatSoles(vm.nextInstallment!.capital!)}',
                    ),
                  if (vm.nextInstallment!.interes != null)
                    _infoRow(
                      'Interés',
                      'S/ ${FormatUtils.formatSoles(vm.nextInstallment!.interes!)}',
                    ),
                  if (vm.nextInstallment!.saldo != null)
                    _infoRow(
                      'Saldo posterior',
                      'S/ ${FormatUtils.formatSoles(vm.nextInstallment!.saldo!)}',
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No tienes cuotas pendientes.',
                  style: TextStyle(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (vm.availableAccounts.isNotEmpty) ...[
          Text(
            'Cuenta origen',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...vm.availableAccounts.map(
            (account) => _buildAccountTile(context, vm, account),
          ),
        ],
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _onPay,
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(vm.isSubmitting ? 'Procesando...' : 'Confirmar pago'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile(
      BuildContext context, CreditPaymentViewModel vm, AccountModel account) {
    final isSelected = vm.selectedAccount?.accountNumber == account.accountNumber;
    final available = account.availableBalance ?? account.balance;
    final tipo = account.accountType;
    final label = tipo.contains('ahorro') || tipo.contains('Ahorro')
        ? 'Cuenta de ahorros'
        : tipo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => vm.selectAccount(account),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: AppColors.secondary, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.secondary : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.accountNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'S/ ${FormatUtils.formatSoles(available)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPay() async {
    final vm = _viewModel;
    if (vm.isSubmitting) return;
    if (vm.nextInstallment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes cuotas pendientes.')),
      );
      return;
    }
    if (vm.selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una cuenta origen.')),
      );
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    await vm.confirmPayment();
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: highlight ? AppColors.secondary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
