import 'package:flutter/material.dart';

import '../../model/request_model.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/requests_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';
import '../widgets/app_bottom_nav.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late final RequestsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RequestsViewModel();
    _viewModel.loadRequests();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Color _estadoColor(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' || 'pendiente' => AppColors.secondary,
      'en evaluación' || 'evaluacion' || 'en_evaluacion' => Colors.orange,
      'aprobada' => Colors.green.shade700,
      'rechazada' => AppColors.primary,
      'desembolsada' => Colors.teal,
      _ => AppColors.textDark,
    };
  }

  String _estadoLabel(String estado) {
    return switch (estado.toLowerCase()) {
      'enviada' => 'Enviada',
      'pendiente' => 'Pendiente',
      'evaluacion' || 'en_evaluacion' => 'En evaluación',
      'en evaluación' => 'En evaluación',
      'aprobada' => 'Aprobada',
      'rechazada' => 'Rechazada',
      'desembolsada' => 'Desembolsada',
      _ => estado,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AlfinAppBar(title: 'Mis solicitudes'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      _viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _viewModel.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_viewModel.requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.grayLight),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no tienes solicitudes registradas.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las solicitudes creadas por tu asesor aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color:
                                  AppColors.textDark.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                'Tus solicitudes de crédito',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 16),
              for (final req in _viewModel.requests) ...[
                _RequestCard(
                  request: req,
                  estadoColor: _estadoColor(req.estado),
                  estadoLabel: _estadoLabel(req.estado),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    required this.request,
    required this.estadoColor,
    required this.estadoLabel,
  });

  final RequestModel request;
  final Color estadoColor;
  final String estadoLabel;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.numeroExpediente,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (req.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                FormatUtils.formatDate(req.createdAt!),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textDark
                                            .withValues(alpha: 0.55)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(
                          widget.estadoLabel,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.white),
                        ),
                        backgroundColor: widget.estadoColor,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MiniMetric(
                          label: 'Monto',
                          value:
                              'S/ ${FormatUtils.formatSoles(req.montoSolicitado)}'),
                      const SizedBox(width: 24),
                      _MiniMetric(
                          label: 'Plazo', value: '${req.plazoMeses} meses'),
                      const SizedBox(width: 24),
                      _MiniMetric(
                          label: 'Cuota',
                          value:
                              'S/ ${FormatUtils.formatSoles(req.cuotaEstimada)}'),
                    ],
                  ),
                  if (req.elegibilidad != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16,
                            color: req.elegibilidad?.toLowerCase() == 'apto'
                                ? Colors.green.shade700
                                : AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Elegibilidad: ${req.elegibilidad}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _expanded
                            ? 'Ocultar detalles'
                            : 'Ver detalle completo',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.secondary),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            _PreEvalSection(request: req),
            if (req.cronograma.isNotEmpty) ...[
              const Divider(height: 1),
              _CronogramaSection(request: req),
            ],
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDark.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 2),
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

class _PreEvalSection extends StatelessWidget {
  const _PreEvalSection({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pre-evaluación crediticia',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (request.scorePreEvaluacion != null)
            _DetailRow(
              label: 'Score',
              value: '${request.scorePreEvaluacion}',
            ),
          if (request.riesgoAsignado != null)
            _DetailRow(label: 'Riesgo', value: request.riesgoAsignado!),
          if (request.ratioCapacidadPago != null)
            _DetailRow(
              label: 'Ratio capacidad pago',
              value:
                  '${(request.ratioCapacidadPago! * 100).toStringAsFixed(1)} %',
            ),
          if (request.scorePreEvaluacion == null &&
              request.riesgoAsignado == null &&
              request.ratioCapacidadPago == null)
            Text(
              'Sin datos de pre-evaluación disponibles.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.55),
                  ),
            ),
        ],
      ),
    );
  }
}

class _CronogramaSection extends StatelessWidget {
  const _CronogramaSection({required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    final visible = request.cronograma.length > 3
        ? request.cronograma.take(3).toList()
        : request.cronograma;
    final hasMore = request.cronograma.length > 3;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cronograma de pagos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _TableHeader('#'),
                  _TableHeader('Fecha'),
                  _TableHeader('Capital'),
                  _TableHeader('Interés'),
                  _TableHeader('Saldo'),
                ],
              ),
              for (final row in visible) ...[
                TableRow(
                  children: [
                    _TableCell('${row.numeroCuota}'),
                    _TableCell(row.fechaPago != null
                        ? FormatUtils.formatDate(row.fechaPago!)
                        : '—'),
                    _TableCell('S/ ${FormatUtils.formatSoles(row.capital)}'),
                    _TableCell('S/ ${FormatUtils.formatSoles(row.interes)}'),
                    _TableCell('S/ ${FormatUtils.formatSoles(row.saldo)}'),
                  ],
                ),
              ],
            ],
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            Text(
              '+${request.cronograma.length - 3} cuotas más',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.6),
                  )),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
