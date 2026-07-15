import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/client_loan_request_model.dart';
import '../repository/client_loan_request_repository.dart';

class ClientLoanRequestViewModel extends ChangeNotifier {
  ClientLoanRequestViewModel({
    ClientLoanRequestRepository? requestRepository,
  }) : _repository =
            requestRepository ?? ClientLoanRequestRepository();

  final ClientLoanRequestRepository _repository;
  ClientLoanRequestDraft? _originalDraft;

  final model = ClientLoanRequestModel();
  int stepIndex = 0;
  bool isSubmitting = false;
  String? submitError;
  String? expedienteCreado;
  String? statusMessage;
  bool success = false;
  bool isLoadingApplicant = false;
  String? applicantLoadMessage;

  /// Carga los datos del usuario autenticado y precarga el formulario.
  /// No sobrescribe si el usuario ya editó los campos manualmente.
  Future<void> loadCurrentLoggedApplicant() async {
    isLoadingApplicant = true;
    applicantLoadMessage = null;
    notifyListeners();

    try {
      final draft = await _repository.getCurrentLoggedApplicant();
      if (draft != null) {
        _originalDraft = draft;
        model.solicitanteNombres = draft.applicantName;
        model.solicitanteDocumento = draft.documentNumber;
        model.solicitanteTelefono = draft.phone;
        applicantLoadMessage =
            'Datos del usuario cargados. Puede editarlos para probar otro caso.';
      } else {
        applicantLoadMessage = 'Complete los datos del solicitante manualmente.';
      }
    } catch (e) {
      debugPrint('[CLIENT_LOAN] error loading applicant: $e');
      applicantLoadMessage = 'Complete los datos del solicitante manualmente.';
    }

    isLoadingApplicant = false;
    notifyListeners();
  }

  /// Restaura los datos originales del usuario logueado.
  void restoreApplicantData() {
    if (_originalDraft == null) return;
    model.solicitanteNombres = _originalDraft!.applicantName;
    model.solicitanteDocumento = _originalDraft!.documentNumber;
    model.solicitanteTelefono = _originalDraft!.phone;
    applicantLoadMessage = 'Datos restaurados.';
    notifyListeners();
  }

  bool get hasOriginalData => _originalDraft != null;

  void rewind() {
    if (stepIndex > 0) stepIndex--;
    notifyListeners();
  }

  bool advance() {
    // Step 0: Solicitante
    if (stepIndex == 0) {
      if (model.solicitanteNombres.trim().isEmpty) {
        statusMessage = 'Ingresa los nombres del solicitante.';
        notifyListeners();
        return false;
      }
      final doc = model.solicitanteDocumento.trim();
      if (doc.isEmpty || doc.length != 8 || int.tryParse(doc) == null) {
        statusMessage = 'Ingresa un DNI válido de 8 dígitos.';
        notifyListeners();
        return false;
      }
      final tel = model.solicitanteTelefono.trim();
      if (tel.isEmpty || tel.length != 9 || int.tryParse(tel) == null) {
        statusMessage = 'Ingresa un teléfono válido de 9 dígitos.';
        notifyListeners();
        return false;
      }
    }

    // Step 1: Negocio
    if (stepIndex == 1) {
      if (model.businessName.trim().isEmpty) {
        statusMessage = 'Ingresa el nombre del negocio.';
        notifyListeners();
        return false;
      }
      final antiguedad =
          int.tryParse(model.businessAgeText.replaceAll(',', '.'));
      if (antiguedad == null || antiguedad <= 0) {
        statusMessage = 'Ingresa una antigüedad válida en meses.';
        notifyListeners();
        return false;
      }
      final ingreso =
          double.tryParse(model.incomeText.replaceAll(',', '.'));
      if (ingreso == null || ingreso <= 0) {
        statusMessage = 'Ingresa ingresos mensuales estimados.';
        notifyListeners();
        return false;
      }
      final gasto =
          double.tryParse(model.expenseText.replaceAll(',', '.'));
      if (gasto == null || gasto < 0) {
        statusMessage = 'Ingresa gastos mensuales.';
        notifyListeners();
        return false;
      }
    }

    // Step 2: Crédito — compute on advance
    if (stepIndex == 2) {
      final monto =
          double.tryParse(model.loanAmountText.replaceAll(',', '.'));
      if (monto == null || monto <= 0) {
        statusMessage = 'Ingresa un monto solicitado válido.';
        notifyListeners();
        return false;
      }
      model.compute();
    }

    statusMessage = null;
    stepIndex++;
    notifyListeners();
    return true;
  }

  Future<void> submit() async {
    if (!model.canCompute) {
      statusMessage = 'Completa los datos para enviar.';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    submitError = null;
    statusMessage = null;
    notifyListeners();

    try {
      // Use DNI from the form to find or create the client
      final clienteId = await _repository.findOrCreateClientByDni(
        documento: model.solicitanteDocumento.trim(),
        nombres: model.solicitanteNombres.trim(),
        telefono: model.solicitanteTelefono.trim(),
        tipoNegocio: model.businessType,
        nombreNegocio: model.businessName,
        antiguedadNegocioMeses:
            int.tryParse(model.businessAgeText.replaceAll(',', '.')) ?? 0,
        ingresosEstimados:
            double.tryParse(model.incomeText.replaceAll(',', '.')) ?? 0,
      );
      if (clienteId == null) {
        throw StateError(
            'No se pudo identificar al cliente. Verifica el DNI ingresado.');
      }

      debugPrint('[CLIENT_LOAN] inserting request');
      final result = await _repository.submitRequest(
        clienteId: clienteId,
        model: model,
      );

      expedienteCreado =
          result['numero_expediente']?.toString() ?? 'EXP-ALF-2026-...';
      success = true;
      debugPrint(
          '[CLIENT_LOAN] request created expediente=$expedienteCreado');
    } catch (e) {
      debugPrint('[CLIENT_LOAN] error=${e.toString()}');
      submitError =
          'No se pudo registrar la solicitud. Verifique la conexión, permisos o configuración de Supabase.';
    }

    isSubmitting = false;
    notifyListeners();
  }

  void reset() {
    stepIndex = 0;
    isSubmitting = false;
    submitError = null;
    expedienteCreado = null;
    statusMessage = null;
    success = false;
    model.solicitanteNombres = '';
    model.solicitanteDocumento = '';
    model.solicitanteTelefono = '';
    model.businessType = 'Comercio';
    model.businessName = '';
    model.businessAgeText = '';
    model.incomeText = '';
    model.expenseText = '';
    model.loanAmountText = '';
    model.loanTerm = 12;
    model.loanPurpose = 'Capital de trabajo: compra de mercadería';
    model.guarantee = 'Sin garantía';
    model.hasInsurance = true;
    model.estadoBuro = 'NORMAL';
    model.entidadesDeudaText = '0';
    model.deudaTotalText = '0';
    model.diasMayorMoraText = '0';
    model.enListaInhabilitados = false;
    model.montoAprobadoText = '';
    model.estimatedInstallment = 0;
    model.totalToPay = 0;
    model.availableCapacity = 0;
    model.capacityRatio = 0;
    model.eligibility = '';
    model.score = 0;
    model.risk = '';
    model.motivoPreEvaluacion = '';
    model.schedule = [];
    notifyListeners();
  }
}
