import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/request_model.dart';
import '../../navigation/app_routes.dart';
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
    unawaited(SessionTimeoutManager.saveActivity());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final success = await _viewModel.refresh();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                      onPressed: _viewModel.loadRequests,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_viewModel.requests.isEmpty) {
            return _EmptyState(onRefresh: _onRefresh);
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
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
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.requestDetail,
                        arguments: req,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 72, color: AppColors.grayLight),
                    const SizedBox(height: 20),
                    Text(
                      'Aún no tienes solicitudes registradas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cuando un asesor registre una solicitud de crédito, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _estadoBadgeColor(String estado) {
  return switch (estado.toLowerCase()) {
    'enviada' || 'pendiente' => Colors.blue.shade700,
    'en evaluación' || 'evaluacion' || 'en_evaluacion' => Colors.amber.shade800,
    'observada' => Colors.orange.shade800,
    'aprobada' || 'desembolsada' => Colors.green.shade700,
    'rechazada' => Colors.red.shade700,
    _ => Colors.grey.shade700,
  };
}

Color _estadoBackgroundColor(String estado) {
  return switch (estado.toLowerCase()) {
    'enviada' || 'pendiente' => Colors.blue.shade50,
    'en evaluación' || 'evaluacion' || 'en_evaluacion' => Colors.amber.shade50,
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final req = request;
    final bgColor = _estadoBackgroundColor(req.estado);
    final badgeColor = _estadoBadgeColor(req.estado);
    final label = _estadoLabel(req.estado);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
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
                    'Ver detalle',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: AppColors.secondary),
                ],
              ),
            ],
          ),
        ),
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
