import 'package:flutter/material.dart';

import '../../model/operation_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';

class OperationDetailScreen extends StatelessWidget {
  const OperationDetailScreen({super.key, required this.operation});

  final OperationModel operation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprobante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
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
                    'Operación registrada correctamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textDark.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 24),
                  _DetailRow(
                    label: 'N° operación',
                    value: operation.numeroOperacion,
                    highlight: true,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Estado',
                    value: operation.estado,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Fecha',
                    value: FormatUtils.formatDate(operation.fecha),
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Tipo',
                    value: operation.tipoOperacion,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Cuenta origen',
                    value: operation.cuentaOrigen,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Cuenta destino',
                    value: operation.cuentaDestino,
                  ),
                  if (operation.descripcion.isNotEmpty) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      label: 'Descripción',
                      value: operation.descripcion,
                    ),
                  ],
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Monto',
                    value: 'S/ ${FormatUtils.formatSoles(operation.monto)}',
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.dashboard),
              child: const Text('Volver al inicio'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.transfers),
              child: const Text('Nueva operación'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.secondary : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
