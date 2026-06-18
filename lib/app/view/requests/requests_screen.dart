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

Color _estadoBackgroundColor(String estado) {
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
    final step = req.statusStepIndex;
    final stepLabel = step >= 0 ? 'Paso ${step + 1} de ${RequestModel.totalSteps}' : '';

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
                        const SizedBox(height: 4),
                        Text(
                          'S/ ${FormatUtils.formatSoles(req.montoSolicitado)} · ${req.plazoMeses} meses',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textDark.withValues(alpha: 0.6),
                              ),
                        ),
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
                      req.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      req.statusDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.textDark.withValues(alpha: 0.55),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (stepLabel.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      stepLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (req.updatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Actualizado: ${FormatUtils.formatDate(req.updatedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.textDark.withValues(alpha: 0.45),
                      ),
                ),
              ],
              const SizedBox(height: 12),
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
