import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/transfers_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key, this.initialOperationType});

  final TransferOperationType? initialOperationType;

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen> {
  late final TransfersViewModel _viewModel;
  late final TextEditingController _originController;
  final _destinationController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = TransfersViewModel(
      initialOperationType: widget.initialOperationType,
    );
    _originController = TextEditingController();
    _viewModel.init();
    _originController.text = _viewModel.originAccount;
    _syncControllersFromViewModel();
    unawaited(SessionTimeoutManager.saveActivity());
  }

  void _syncControllersFromViewModel() {
    _destinationController.text = _viewModel.destinationAccount;
    _amountController.text = _viewModel.amountText;
    _descriptionController.text = _viewModel.description;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlfinAppBar(
        title: 'Transferencias y Pagos',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return switch (_viewModel.step) {
            TransferFlowStep.form => _buildForm(context),
            TransferFlowStep.summary => _buildSummary(context),
            TransferFlowStep.success => _buildSuccess(context),
          };
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final vm = _viewModel;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Nueva operación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<TransferOperationType>(
          segments: const [
            ButtonSegment(
              value: TransferOperationType.transferencia,
              label: Text('Transferencia', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.swap_horiz, size: 18),
            ),
            ButtonSegment(
              value: TransferOperationType.pagoCredito,
              label: Text('Crédito', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.credit_card, size: 18),
            ),
            ButtonSegment(
              value: TransferOperationType.pagoServicio,
              label: Text('Servicio', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.receipt, size: 18),
            ),
          ],
          selected: {vm.operationType},
          onSelectionChanged: (s) {
            vm.setOperationType(s.first);
            _syncControllersFromViewModel();
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  readOnly: true,
                  controller: _originController,
                  decoration: InputDecoration(
                    labelText: 'Cuenta origen',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _destinationController,
                  onChanged: vm.setDestination,
                  readOnly: vm.operationType != TransferOperationType.transferencia,
                  decoration: InputDecoration(
                    labelText: vm.operationType ==
                            TransferOperationType.transferencia
                        ? 'Cuenta destino'
                        : 'Destino / referencia',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    errorText: vm.destinationError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  onChanged: vm.setAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Monto (S/)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    errorText: vm.amountError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  onChanged: vm.setDescription,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: vm.goToSummary,
            child: const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final vm = _viewModel;
    final amount = vm.parsedAmount ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Resumen de operación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(label: 'Tipo', value: vm.operationTypeLabel),
                _SummaryRow(label: 'Origen', value: vm.originAccount),
                _SummaryRow(label: 'Destino', value: vm.destinationAccount),
                _SummaryRow(
                  label: 'Monto',
                  value: 'S/ ${FormatUtils.formatSoles(amount)}',
                  highlight: true,
                ),
                _SummaryRow(
                  label: 'Descripción',
                  value: vm.description.trim().isEmpty
                      ? '—'
                      : vm.description.trim(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: vm.isLoading ? null : vm.confirmOperation,
            child: vm.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Confirmar operación'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: vm.isLoading ? null : vm.goBackToForm,
          child: const Text('Volver al formulario'),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final transfer = _viewModel.completedTransfer!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'Operación exitosa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.purpleSupport,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Operación registrada correctamente.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 20),
                _SummaryRow(
                  label: 'N° operación',
                  value: transfer.operationNumber,
                  highlight: true,
                ),
                _SummaryRow(
                  label: 'Fecha',
                  value: FormatUtils.formatDate(transfer.date),
                ),
                _SummaryRow(
                  label: 'Monto',
                  value: 'S/ ${FormatUtils.formatSoles(transfer.amount)}',
                  highlight: true,
                ),
                _SummaryRow(label: 'Tipo', value: _viewModel.operationTypeLabel),
                _SummaryRow(label: 'Estado', value: transfer.status),
                _SummaryRow(label: 'Destino', value: transfer.destinationAccount),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              _viewModel.resetForNewOperation();
              _syncControllersFromViewModel();
            },
            child: const Text('Nueva operación'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.dashboard),
            child: const Text('Volver al inicio'),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: highlight ? AppColors.secondary : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
