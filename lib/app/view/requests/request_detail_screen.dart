import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/request_model.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.request});

  final RequestModel request;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(SessionTimeoutManager.saveActivity());
  }

  Color _badgeColor(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' || 'pendiente' => Colors.blue.shade700,
      'en evaluación' || 'evaluacion' || 'en_evaluacion' =>
        Colors.amber.shade800,
      'observada' => Colors.orange.shade800,
      'aprobada' || 'desembolsada' => Colors.green.shade700,
      'rechazada' => Colors.red.shade700,
      _ => Colors.grey.shade700,
    };
  }

  Color _bgColor(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' || 'pendiente' => Colors.blue.shade50,
      'en evaluación' || 'evaluacion' || 'en_evaluacion' =>
        Colors.amber.shade50,
      'observada' => Colors.orange.shade50,
      'aprobada' || 'desembolsada' => Colors.green.shade50,
      'rechazada' => Colors.red.shade50,
      _ => Colors.grey.shade50,
    };
  }

  String _estadoLabel(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' => 'Enviada',
      'pendiente' => 'Pendiente',
      'evaluacion' || 'en_evaluacion' => 'En evaluación',
      'en evaluación' => 'En evaluación',
      'observada' => 'Observada',
      'aprobada' => 'Aprobada',
      'rechazada' => 'Rechazada',
      'desembolsada' => 'Desembolsada',
      _ => estado,
    };
  }

  void _contactarAsesor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contactar asesor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un asesor se comunicará contigo para revisar esta solicitud.',
            ),
            const SizedBox(height: 12),
            Text(
              'Expediente: ${widget.request.numeroExpediente}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final badgeColor = _badgeColor(req.estado);
    final bgBadge = _bgColor(req.estado);
    final estadoLabel = _estadoLabel(req.estado);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          req.numeroExpediente,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          req.numeroExpediente,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgBadge,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          estadoLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (req.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Creada: ${FormatUtils.formatDate(req.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.textDark.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles del crédito',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _MetricRow(
                    label: 'Monto solicitado',
                    value:
                        'S/ ${FormatUtils.formatSoles(req.montoSolicitado)}',
                  ),
                  const SizedBox(height: 10),
                  _MetricRow(
                    label: 'Plazo',
                    value: '${req.plazoMeses} meses',
                  ),
                  const SizedBox(height: 10),
                  _MetricRow(
                    label: 'Cuota estimada',
                    value:
                        'S/ ${FormatUtils.formatSoles(req.cuotaEstimada)}',
                  ),
                  if (req.elegibilidad != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          req.elegibilidad?.toLowerCase() == 'apto'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 18,
                          color: req.elegibilidad?.toLowerCase() == 'apto'
                              ? Colors.green.shade700
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Elegibilidad: ${req.elegibilidad}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (req.scorePreEvaluacion != null ||
                req.riesgoAsignado != null ||
                req.ratioCapacidadPago != null) ...[
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-evaluación crediticia',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (req.scorePreEvaluacion != null)
                      _MetricRow(
                        label: 'Score',
                        value: '${req.scorePreEvaluacion}',
                      ),
                    if (req.scorePreEvaluacion != null &&
                        req.riesgoAsignado != null)
                      const SizedBox(height: 10),
                    if (req.riesgoAsignado != null)
                      _MetricRow(
                        label: 'Riesgo',
                        value: req.riesgoAsignado!,
                      ),
                    if ((req.scorePreEvaluacion != null ||
                            req.riesgoAsignado != null) &&
                        req.ratioCapacidadPago != null)
                      const SizedBox(height: 10),
                    if (req.ratioCapacidadPago != null)
                      _MetricRow(
                        label: 'Ratio capacidad de pago',
                        value:
                            '${(req.ratioCapacidadPago! * 100).toStringAsFixed(1)} %',
                      ),
                  ],
                ),
              ),
            ],
            if (req.cronograma.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cronograma de pagos',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${req.cronograma.length} cuota${req.cronograma.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textDark
                                .withValues(alpha: 0.55),
                          ),
                    ),
                    const SizedBox(height: 16),
                    for (final row in req.cronograma) ...[
                      _CuotaCard(row: row),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _contactarAsesor,
                icon: const Icon(Icons.headset_mic_outlined),
                label: const Text('Contactar asesor'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CuotaCard extends StatelessWidget {
  const _CuotaCard({required this.row});

  final RequestScheduleRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${row.numeroCuota}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  row.fechaPago != null
                      ? FormatUtils.formatDate(row.fechaPago!)
                      : '—',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Text(
                  'S/ ${FormatUtils.formatSoles(row.cuota)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _CuotaDetail(
                    label: 'Capital',
                    value: 'S/ ${FormatUtils.formatSoles(row.capital)}'),
                const SizedBox(width: 16),
                _CuotaDetail(
                    label: 'Interés',
                    value: 'S/ ${FormatUtils.formatSoles(row.interes)}'),
                const SizedBox(width: 16),
                _CuotaDetail(
                    label: 'Saldo',
                    value: 'S/ ${FormatUtils.formatSoles(row.saldo)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CuotaDetail extends StatelessWidget {
  const _CuotaDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.textDark.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
