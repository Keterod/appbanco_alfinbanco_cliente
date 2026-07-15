import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/request_model.dart';
import '../../navigation/app_routes.dart';
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
      'enviada' || 'pendiente' || 'enviado' => Colors.blue.shade700,
      'en evaluación' || 'evaluacion' || 'en_evaluacion' || 'recibido_comite' =>
        Colors.amber.shade800,
      'observada' || 'condicionado' => Colors.orange.shade800,
      'aprobada' || 'aprobado' || 'desembolsada' || 'desembolsado' =>
        Colors.green.shade700,
      'rechazada' || 'rechazado' => Colors.red.shade700,
      _ => Colors.grey.shade700,
    };
  }

  Color _bgColor(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' || 'pendiente' || 'enviado' => Colors.blue.shade50,
      'en evaluación' || 'evaluacion' || 'en_evaluacion' || 'recibido_comite' =>
        Colors.amber.shade50,
      'observada' || 'condicionado' => Colors.orange.shade50,
      'aprobada' || 'aprobado' || 'desembolsada' || 'desembolsado' =>
        Colors.green.shade50,
      'rechazada' || 'rechazado' => Colors.red.shade50,
      _ => Colors.grey.shade50,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.numeroExpediente,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (req.updatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Actualizado: ${FormatUtils.formatDate(req.updatedAt!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textDark
                                            .withValues(alpha: 0.55)),
                              ),
                            ] else if (req.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Creada: ${FormatUtils.formatDate(req.createdAt!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textDark
                                            .withValues(alpha: 0.55)),
                              ),
                            ],
                            if (req.hasUpdate) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 8, color: Colors.amber.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tu expediente tiene una actualización.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
                          req.statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (req.normalizedStatus != 'borrador' &&
                req.statusStepIndex >= 0) ...[
              const SizedBox(height: 16),
              _buildTimeline(context, req),
            ],
            if (req.hasDecision) ...[
              const SizedBox(height: 16),
              _buildDecisionCard(context, req),
            ] else ...[
              const SizedBox(height: 16),
              _buildNoDecisionCard(context, req),
            ],
            if (req.isDisbursed) ...[
              const SizedBox(height: 16),
              _buildDisbursedCard(context, req),
            ] else if (req.isApproved) ...[
              const SizedBox(height: 16),
              _buildApprovedCard(context, req),
            ],
            if (req.solicitanteNombre != null ||
                req.solicitanteDocumento != null ||
                req.solicitanteTelefono != null) ...[
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del solicitante',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (req.solicitanteNombre != null)
                      _MetricRow(
                        label: 'Nombre',
                        value: req.solicitanteNombre!,
                      ),
                    if (req.solicitanteDocumento != null)
                      _MetricRow(
                        label: 'Documento',
                        value: req.solicitanteDocumento!,
                      ),
                    if (req.solicitanteTelefono != null)
                      _MetricRow(
                        label: 'Teléfono',
                        value: req.solicitanteTelefono!,
                      ),
                  ],
                ),
              ),
            ],
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
                    if (req.estadoBuro != null)
                      const SizedBox(height: 10),
                    if (req.estadoBuro != null)
                      _MetricRow(
                        label: 'Estado buró',
                        value: req.estadoBuro!,
                      ),
                    if (req.entidadesDeuda != null)
                      const SizedBox(height: 10),
                    if (req.entidadesDeuda != null)
                      _MetricRow(
                        label: 'Entidades deuda',
                        value: '${req.entidadesDeuda}',
                      ),
                    if (req.deudaTotal != null)
                      const SizedBox(height: 10),
                    if (req.deudaTotal != null)
                      _MetricRow(
                        label: 'Deuda total',
                        value: 'S/ ${FormatUtils.formatSoles(req.deudaTotal!)}',
                      ),
                    if (req.diasMayorMora != null)
                      const SizedBox(height: 10),
                    if (req.diasMayorMora != null)
                      _MetricRow(
                        label: 'Días mayor mora',
                        value: '${req.diasMayorMora}',
                      ),
                    if (req.enListaInhabilitados != null)
                      const SizedBox(height: 10),
                    if (req.enListaInhabilitados != null)
                      _MetricRow(
                        label: 'Lista inhabilitados',
                        value: req.enListaInhabilitados! ? 'Sí' : 'No',
                      ),
                    if (req.motivoPreEvaluacion != null)
                      const SizedBox(height: 10),
                    if (req.motivoPreEvaluacion != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Motivo: ${req.motivoPreEvaluacion!}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
                            color: AppColors.textDark.withValues(alpha: 0.55),
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

  Widget _buildTimeline(BuildContext context, RequestModel req) {
    final currentStep = req.statusStepIndex;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguimiento del expediente',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < RequestModel.totalSteps; i++) ...[
            _buildTimelineRow(i, currentStep, req),
            if (i < RequestModel.totalSteps - 1)
              Container(
                width: 2,
                height: 28,
                margin: const EdgeInsets.only(left: 15),
                color: i < currentStep
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineRow(int index, int currentStep, RequestModel req) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    final isNA = index == 4 && req.isRejected;

    IconData icon;
    Color iconColor;
    Color bgColor;

    if (isNA) {
      icon = Icons.not_interested;
      iconColor = Colors.grey;
      bgColor = Colors.grey.shade100;
    } else if (isCompleted) {
      icon = Icons.check_circle;
      iconColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.1);
    } else if (isCurrent) {
      icon = Icons.radio_button_checked;
      iconColor = AppColors.secondary;
      bgColor = AppColors.secondary.withValues(alpha: 0.12);
    } else {
      icon = Icons.radio_button_unchecked;
      iconColor = Colors.grey.shade400;
      bgColor = Colors.transparent;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RequestModel.timelineSteps[index],
                  style: TextStyle(
                    fontWeight: isCurrent || isCompleted
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isNA
                        ? Colors.grey
                        : isCurrent
                            ? AppColors.secondary
                            : AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
                if (isCurrent || isNA) ...[
                  const SizedBox(height: 2),
                  Text(
                    isNA
                        ? 'No aplica'
                        : req.statusDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: isNA
                          ? Colors.grey
                          : AppColors.textDark.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                if (index == 3 && isCurrent && req.isRejected && req.motivoRechazo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Motivo: ${req.motivoRechazo}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionCard(BuildContext context, RequestModel req) {
    final isRej = req.isRejected;
    final isCond = req.isConditioned;
    final isApproved = req.isApproved;
    final isDes = req.isDisbursed;

    String title;
    String message;
    Color color;

    if (isDes) {
      title = 'Desembolsado';
      message = 'Tu crédito ya fue desembolsado.';
      color = Colors.green;
    } else if (isRej) {
      title = 'Rechazado';
      message = req.motivoRechazo ?? 'Tu solicitud no fue aprobada.';
      color = Colors.red;
    } else if (isCond) {
      title = 'Aprobado con condiciones';
      message = 'El comité aprobó un monto o condición diferente al solicitado.';
      color = Colors.orange;
    } else {
      title = 'Aprobado';
      message = 'Tu crédito fue aprobado y se encuentra pendiente de desembolso.';
      color = Colors.green;
    }

    final monto = req.montoAprobado ?? req.montoSolicitado;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isRej ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  color: color),
              const SizedBox(width: 8),
              Text(
                'Resultado de evaluación',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                if (!isRej && (req.montoAprobado != null || isApproved)) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Monto: S/ ${FormatUtils.formatSoles(monto)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                if (req.fechaDecision != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Decisión: ${FormatUtils.formatDate(req.fechaDecision!)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withValues(alpha: 0.6)),
                  ),
                ],
                if (isDes && req.fechaDesembolso != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Desembolso: ${FormatUtils.formatDate(req.fechaDesembolso!)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withValues(alpha: 0.6)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDecisionCard(BuildContext context, RequestModel req) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Resultado de evaluación',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no hay decisión final.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Te avisaremos cuando tu expediente cambie de estado.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisbursedCard(BuildContext context, RequestModel req) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Crédito desembolsado',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Este crédito ya está disponible en tus productos.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.credits),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Ver en Mis créditos'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedCard(BuildContext context, RequestModel req) {
    if (req.isConditioned) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Aprobado con condiciones',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aprobado con condiciones',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (req.montoAprobado != null) ...[
                    Text(
                      'Monto solicitado: S/ ${FormatUtils.formatSoles(req.montoSolicitado)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Monto aprobado: S/ ${FormatUtils.formatSoles(req.montoAprobado!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'El comité aprobó el crédito con ajustes en el monto o condiciones. Pendiente de desembolso.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Aprobado',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendiente de desembolso',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cuando el desembolso se registre, aparecerá en tus créditos.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
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
