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

  final model = ClientLoanRequestModel();
  int stepIndex = 0;
  bool isSubmitting = false;
  String? submitError;
  String? expedienteCreado;
  String? statusMessage;
  bool success = false;

  void rewind() {
    if (stepIndex > 0) stepIndex--;
    notifyListeners();
  }

  bool advance() {
    if (stepIndex == 0) {
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

    if (stepIndex == 1) {
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
      final clienteId = await _repository.getClienteId();
      if (clienteId == null) {
        throw StateError(
            'No se pudo identificar al cliente. Verifica tu sesión.');
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
      submitError = 'No se pudo enviar la solicitud. Intente nuevamente.';
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
    model.estimatedInstallment = 0;
    model.totalToPay = 0;
    model.availableCapacity = 0;
    model.capacityRatio = 0;
    model.eligibility = '';
    model.score = 0;
    model.risk = '';
    model.schedule = [];
    notifyListeners();
  }
}
