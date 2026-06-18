import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/operation_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/operations_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  late final OperationsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OperationsViewModel();
    unawaited(_viewModel.loadOperations());
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlfinAppBar(
        title: 'Mis operaciones',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null && vm.operations.isEmpty) {
            return _buildError(context, vm);
          }

          if (vm.operations.isEmpty) {
            return _buildEmpty(context);
          }

          return RefreshIndicator(
            onRefresh: () => vm.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: vm.operations.length,
              itemBuilder: (context, index) {
                final op = vm.operations[index];
                return _OperationCard(
                  operation: op,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.operationDetail,
                    arguments: op,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, OperationsViewModel vm) {
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
              vm.errorMessage ?? 'Error de conexión',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _viewModel.loadOperations(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes operaciones registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las transferencias y pagos que realices aparecerán aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.operation,
    required this.onTap,
  });

  final OperationModel operation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForType(operation.tipoOperacion),
                    size: 20,
                    color: AppColors.purpleSupport,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      operation.tipoOperacion,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  _StatusChip(estado: operation.estado),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                operation.numeroOperacion,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.formatDate(operation.fecha),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      operation.cuentaDestino,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.6),
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'S/ ${FormatUtils.formatSoles(operation.monto)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String tipo) {
    return switch (tipo.toLowerCase()) {
      'transferencia' => Icons.swap_horiz_rounded,
      'pago de crédito' => Icons.credit_card_rounded,
      'pago de servicio' => Icons.receipt_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _colorForStatus(String estado) {
    return switch (estado.toLowerCase()) {
      'completada' || 'completado' => Colors.green.shade700,
      'pendiente' => AppColors.secondary,
      'rechazada' || 'rechazado' => AppColors.primary,
      _ => Colors.grey.shade600,
    };
  }
}
