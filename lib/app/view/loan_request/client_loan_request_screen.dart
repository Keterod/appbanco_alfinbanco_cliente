import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/session/session_timeout_manager.dart';
import '../../model/client_loan_request_model.dart';
import '../../navigation/app_routes.dart';
import '../../ui/theme/app_colors.dart';
import '../../util/format_utils.dart';
import '../../viewmodel/client_loan_request_viewmodel.dart';
import '../widgets/alfin_app_bar.dart';

class ClientLoanRequestScreen extends StatefulWidget {
  const ClientLoanRequestScreen({super.key});

  @override
  State<ClientLoanRequestScreen> createState() =>
      _ClientLoanRequestScreenState();
}

class _ClientLoanRequestScreenState extends State<ClientLoanRequestScreen> {
  late final ClientLoanRequestViewModel _vm;
  final _solicitanteNombreController = TextEditingController();
  final _solicitanteDocController = TextEditingController();
  final _solicitanteTelController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _amountController = TextEditingController();
  final _deudaTotalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = ClientLoanRequestViewModel();
    unawaited(_initLoad());
    unawaited(SessionTimeoutManager.saveActivity());
  }

  Future<void> _initLoad() async {
    await _vm.loadCurrentLoggedApplicant();
    if (mounted) {
      _updateSolicitanteControllers();
    }
  }

  void _updateSolicitanteControllers() {
    _solicitanteNombreController.text = _vm.model.solicitanteNombres;
    _solicitanteDocController.text = _vm.model.solicitanteDocumento;
    _solicitanteTelController.text = _vm.model.solicitanteTelefono;
  }

  @override
  void dispose() {
    _vm.dispose();
    _solicitanteNombreController.dispose();
    _solicitanteDocController.dispose();
    _solicitanteTelController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
    _amountController.dispose();
    _deudaTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AlfinAppBar(
        title: 'Solicitar Crédito',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.success && _vm.expedienteCreado != null) {
            return _buildSuccess(context);
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final steps = ['Solicitante', 'Negocio', 'Crédito', 'Confirmar'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: List.generate(steps.length, (i) {
              final isActive = i == _vm.stepIndex;
              final isDone = i < _vm.stepIndex;
              return Expanded(
                child: Row(
                  children: [
                    if (i > 0) Expanded(child: Container(height: 2, color: isDone ? AppColors.primary : Colors.grey.shade300)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive || isDone ? AppColors.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive || isDone ? AppColors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (i < steps.length - 1) Expanded(child: Container(height: 2, color: isDone ? AppColors.primary : Colors.grey.shade300)),
                  ],
                ),
              );
            }),
          ),
        ),
        if (_vm.statusMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _vm.statusMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: _vm.stepIndex,
            children: [
              _buildStepSolicitante(context),
              _buildStepNegocio(context),
              _buildStepCredito(context),
              _buildStepConfirmar(context),
            ],
          ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildStepSolicitante(BuildContext context) {
    final m = _vm.model;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Datos del solicitante',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _solicitanteNombreController,
          onChanged: (v) => m.solicitanteNombres = v,
          decoration: const InputDecoration(
            labelText: 'Nombres y apellidos',
            prefixIcon: Icon(Icons.person_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _solicitanteDocController,
          onChanged: (v) => m.solicitanteDocumento = v,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: const InputDecoration(
            labelText: 'DNI / documento',
            prefixIcon: Icon(Icons.assignment_ind_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _solicitanteTelController,
          onChanged: (v) => m.solicitanteTelefono = v,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
            counterText: '',
          ),
        ),
        if (_vm.applicantLoadMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _vm.applicantLoadMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          if (_vm.hasOriginalData) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  _vm.restoreApplicantData();
                  _updateSolicitanteControllers();
                },
                icon: const Icon(Icons.restore_outlined, size: 16),
                label: const Text('Restaurar mis datos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
        Text('Buró de crédito',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: m.estadoBuro,
          items: ClientLoanRequestModel.bureauStates
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            m.estadoBuro = v ?? 'NORMAL';
            m.notifyAll();
          },
          decoration: const InputDecoration(
            labelText: 'Estado buró',
            prefixIcon: Icon(Icons.credit_score_outlined),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<bool>(
          initialValue: m.enListaInhabilitados,
          items: const [
            DropdownMenuItem(value: false, child: Text('No')),
            DropdownMenuItem(value: true, child: Text('Sí')),
          ],
          onChanged: (v) {
            m.enListaInhabilitados = v ?? false;
            m.notifyAll();
          },
          decoration: const InputDecoration(
            labelText: '¿En lista de inhabilitados?',
            prefixIcon: Icon(Icons.gavel_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deudaTotalController,
          onChanged: (v) => m.deudaTotalText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Deuda total (S/)',
            prefixIcon: Icon(Icons.money_off_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => m.entidadesDeudaText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Entidades con deuda',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => m.diasMayorMoraText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Días de mayor mora',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildStepNegocio(BuildContext context) {
    final m = _vm.model;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Datos del negocio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: m.businessType,
          items: ClientLoanRequestModel.businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) {
            m.businessType = v ?? 'Comercio';
            m.notifyAll();
          },
          decoration: const InputDecoration(labelText: 'Tipo de negocio', prefixIcon: Icon(Icons.store_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          onChanged: (v) => m.businessName = v,
          decoration: const InputDecoration(labelText: 'Nombre del negocio', prefixIcon: Icon(Icons.badge_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ageController,
          onChanged: (v) => m.businessAgeText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Antigüedad (meses)', prefixIcon: Icon(Icons.calendar_month_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _incomeController,
          onChanged: (v) => m.incomeText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Ingresos mensuales estimados (S/)', prefixIcon: Icon(Icons.trending_up_outlined)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _expenseController,
          onChanged: (v) => m.expenseText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Gastos mensuales (S/)', prefixIcon: Icon(Icons.trending_down_outlined)),
        ),
      ],
    );
  }

  Widget _buildStepCredito(BuildContext context) {
    final m = _vm.model;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Datos del crédito',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          onChanged: (v) => m.loanAmountText = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto solicitado (S/)', prefixIcon: Icon(Icons.money_outlined)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: m.loanTerm,
          items: ClientLoanRequestModel.terms.map((t) => DropdownMenuItem(value: t, child: Text('$t meses'))).toList(),
          onChanged: (v) {
            m.loanTerm = v ?? 12;
            m.notifyAll();
          },
          decoration: const InputDecoration(labelText: 'Plazo', prefixIcon: Icon(Icons.schedule_outlined)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: m.loanPurpose,
          items: ClientLoanRequestModel.purposes.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {
            m.loanPurpose = v ?? ClientLoanRequestModel.purposes.first;
            m.notifyAll();
          },
          decoration: const InputDecoration(labelText: 'Destino del crédito', prefixIcon: Icon(Icons.flag_outlined)),
          isExpanded: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: m.guarantee,
          items: ClientLoanRequestModel.guarantees.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) {
            m.guarantee = v ?? ClientLoanRequestModel.guarantees.first;
            m.notifyAll();
          },
          decoration: const InputDecoration(labelText: 'Garantía', prefixIcon: Icon(Icons.verified_outlined)),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: m.hasInsurance ? 'Sí' : 'No',
          items: const [
            DropdownMenuItem(value: 'Sí', child: Text('Sí')),
            DropdownMenuItem(value: 'No', child: Text('No')),
          ],
          onChanged: (v) {
            m.hasInsurance = v == 'Sí';
            m.notifyAll();
          },
          decoration: const InputDecoration(labelText: 'Seguro de desgravamen', prefixIcon: Icon(Icons.shield_outlined)),
        ),
      ],
    );
  }

  Widget _buildStepConfirmar(BuildContext context) {
    final m = _vm.model;
    final monto = double.tryParse(m.loanAmountText.replaceAll(',', '.')) ?? 0;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Confirma tu solicitud',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Datos del solicitante', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 8),
                _row('Nombre', m.solicitanteNombres),
                _row('DNI', m.solicitanteDocumento),
                _row('Teléfono', m.solicitanteTelefono),
                const Divider(height: 24),
                Text('Buró de crédito', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 8),
                _row('Estado buró', m.estadoBuro),
                _row('Entidades deuda', '${m.entidadesDeuda}'),
                _row('Deuda total', 'S/ ${FormatUtils.formatSoles(m.deudaTotal)}'),
                _row('Días mora', '${m.diasMayorMora}'),
                _row('Inhabilitado', m.enListaInhabilitados ? 'Sí' : 'No'),
                const Divider(height: 24),
                Text('Datos del negocio', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 8),
                _row('Tipo', m.businessType),
                _row('Negocio', m.businessName),
                _row('Antigüedad', '${m.businessAgeText} meses'),
                _row('Ingresos', 'S/ ${FormatUtils.formatSoles(m.monthlyIncome)}'),
                _row('Gastos', 'S/ ${FormatUtils.formatSoles(m.monthlyExpenses)}'),
                const Divider(height: 24),
                Text('Datos del crédito', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 8),
                _row('Monto', 'S/ ${FormatUtils.formatSoles(monto)}'),
                _row('Plazo', '${m.loanTerm} meses'),
                _row('Destino', m.loanPurpose),
                _row('Garantía', m.guarantee),
                _row('Desgravamen', m.hasInsurance ? 'Sí' : 'No'),
                const Divider(height: 24),
                Text('Resultados', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 8),
                _row('TEA', '${m.tea.toStringAsFixed(2)}%'),
                _row('Cuota estimada', 'S/ ${FormatUtils.formatSoles(m.estimatedInstallment)}', bold: true),
                _row('Total a pagar', 'S/ ${FormatUtils.formatSoles(m.totalToPay)}'),
                _row('Capacidad disponible', 'S/ ${FormatUtils.formatSoles(m.availableCapacity)}'),
                _row('Ratio cuota/capacidad', '${(m.capacityRatio * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _eligibilityColor(m.eligibility).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _eligibilityColor(m.eligibility).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_eligibilityIcon(m.eligibility), color: _eligibilityColor(m.eligibility)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.eligibility, style: TextStyle(fontWeight: FontWeight.w700, color: _eligibilityColor(m.eligibility))),
                                Text('Score: ${m.score} · Riesgo: ${m.risk}', style: TextStyle(fontSize: 12, color: AppColors.textDark.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (m.motivoPreEvaluacion.isNotEmpty)
                        const SizedBox(height: 8),
                      if (m.motivoPreEvaluacion.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Motivo: ${m.motivoPreEvaluacion}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_vm.submitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_vm.submitError!, style: TextStyle(color: Colors.red.shade700)),
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_vm.stepIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _vm.isSubmitting ? null : _vm.rewind,
                  child: const Text('Anterior'),
                ),
              ),
            if (_vm.stepIndex > 0) const SizedBox(width: 12),
            Expanded(
              child: _vm.stepIndex < 3
                  ? ElevatedButton(
                      onPressed: _vm.advance,
                      child: const Text('Siguiente'),
                    )
                  : ElevatedButton(
                      onPressed: _vm.isSubmitting ? null : _vm.submit,
                      child: _vm.isSubmitting
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                          : const Text('Enviar solicitud'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        children: [
          Card(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, size: 72, color: Colors.green.shade600),
                  const SizedBox(height: 16),
                  Text(
                    'Solicitud enviada correctamente',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.purpleSupport),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _summaryRow('N° expediente', _vm.expedienteCreado!),
                  _summaryRow('Estado', 'Enviado'),
                  const SizedBox(height: 12),
                  Text(
                    'Tu solicitud ha sido registrada y será evaluada.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textDark.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.requests),
              child: const Text('Ver Mis Solicitudes'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard),
              child: const Text('Volver al inicio'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textDark.withValues(alpha: 0.6)))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.6)))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Color _eligibilityColor(String e) {
    switch (e) {
      case 'APTO':
        return Colors.green;
      case 'OBSERVADO':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _eligibilityIcon(String e) {
    switch (e) {
      case 'APTO':
        return Icons.check_circle_outlined;
      case 'OBSERVADO':
        return Icons.warning_amber_rounded;
      default:
        return Icons.cancel_outlined;
    }
  }
}
