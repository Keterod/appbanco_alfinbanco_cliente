import 'dart:math';

import 'package:flutter/foundation.dart';

class ClientLoanRequestModel extends ChangeNotifier {
  static const List<String> businessTypes = [
    'Comercio',
    'Servicios',
    'Producción',
    'Agropecuario',
  ];
  static const List<int> terms = [6, 12, 18, 24, 36];
  static const List<String> purposes = [
    'Capital de trabajo: compra de mercadería',
    'Compra de maquinaria / equipo',
    'Ampliación de local',
    'Refinanciamiento de deudas',
    'Otro',
  ];
  static const List<String> guarantees = [
    'Sin garantía',
    'Aval',
    'Hipotecaria',
    'Prendaria',
  ];
  static const List<String> bureauStates = [
    'NORMAL',
    'CPP',
    'DEFICIENTE',
    'DUDOSO',
    'PERDIDA',
  ];

  // Solicitante
  String solicitanteNombres = '';
  String solicitanteDocumento = '';
  String solicitanteTelefono = '';

  // Negocio
  String businessType = businessTypes.first;
  String businessName = '';
  String businessAgeText = '';
  String incomeText = '';
  String expenseText = '';

  // Crédito
  String loanAmountText = '';
  int loanTerm = terms.first;
  String loanPurpose = purposes.first;
  String guarantee = guarantees.first;
  bool hasInsurance = true;

  // Buró
  String estadoBuro = bureauStates.first;
  String entidadesDeudaText = '0';
  String deudaTotalText = '0';
  String diasMayorMoraText = '0';
  bool enListaInhabilitados = false;

  // Aprobado monto (para condicionado simulation — editable en preview)
  String montoAprobadoText = '';

  // Computed
  double tea = 0;
  double tem = 0;
  double estimatedInstallment = 0;
  double totalToPay = 0;
  double monthlyIncome = 0;
  double monthlyExpenses = 0;
  double availableCapacity = 0;
  double capacityRatio = 0;
  String eligibility = '';
  int score = 0;
  String risk = '';
  String motivoPreEvaluacion = '';
  List<Map<String, dynamic>> schedule = [];

  bool get canCompute =>
      (double.tryParse(incomeText.replaceAll(',', '.')) ?? 0) > 0 &&
      (double.tryParse(loanAmountText.replaceAll(',', '.')) ?? 0) > 0;

  double get montoAprobado =>
      double.tryParse(montoAprobadoText.replaceAll(',', '.')) ?? 0;

  int get entidadesDeuda =>
      int.tryParse(entidadesDeudaText.replaceAll(',', '.')) ?? 0;

  double get deudaTotal =>
      double.tryParse(deudaTotalText.replaceAll(',', '.')) ?? 0;

  int get diasMayorMora =>
      int.tryParse(diasMayorMoraText.replaceAll(',', '.')) ?? 0;

  void compute() {
    final monto = double.tryParse(loanAmountText.replaceAll(',', '.')) ?? 0;
    final plazo = loanTerm;

    monthlyIncome = double.tryParse(incomeText.replaceAll(',', '.')) ?? 0;
    monthlyExpenses = double.tryParse(expenseText.replaceAll(',', '.')) ?? 0;

    if (monto <= 0 || plazo <= 0) {
      _resetComputed();
      return;
    }

    debugPrint('[CLIENT_LOAN] calculating installment');
    tea = hasInsurance ? 40.92 : 43.92;
    tem = pow(1 + tea / 100, 1 / 12) - 1;

    if (tem <= 0) {
      estimatedInstallment = 0;
      totalToPay = 0;
    } else {
      final denom = 1 - pow(1 + tem, -plazo);
      estimatedInstallment = denom != 0 ? monto * tem / denom : 0;
      totalToPay = estimatedInstallment * plazo;
    }

    availableCapacity = monthlyIncome - monthlyExpenses;
    capacityRatio =
        availableCapacity > 0 ? estimatedInstallment / availableCapacity : 999;

    _evaluate(porMontoAprobado: false);
    _generateSchedule(monto, plazo);
  }

  void computeWithMontoAprobado(double montoAprobadoVal) {
    final plazo = loanTerm;
    if (montoAprobadoVal <= 0 || plazo <= 0) return;

    monthlyIncome = double.tryParse(incomeText.replaceAll(',', '.')) ?? 0;
    monthlyExpenses = double.tryParse(expenseText.replaceAll(',', '.')) ?? 0;

    tea = hasInsurance ? 40.92 : 43.92;
    tem = pow(1 + tea / 100, 1 / 12) - 1;

    if (tem <= 0) {
      estimatedInstallment = 0;
      totalToPay = 0;
    } else {
      final denom = 1 - pow(1 + tem, -plazo);
      estimatedInstallment = denom != 0 ? montoAprobadoVal * tem / denom : 0;
      totalToPay = estimatedInstallment * plazo;
    }

    availableCapacity = monthlyIncome - monthlyExpenses;
    capacityRatio =
        availableCapacity > 0 ? estimatedInstallment / availableCapacity : 999;

    _evaluate(porMontoAprobado: true);
    _generateSchedule(montoAprobadoVal, plazo);
  }

  void _evaluate({bool porMontoAprobado = false}) {
    // Combined pre-evaluation: bureau + capacity

    // 1. Inhabilitados → NO APTO
    if (enListaInhabilitados) {
      eligibility = 'NO APTO';
      score = 20;
      risk = 'Alto';
      motivoPreEvaluacion = 'Cliente en lista de inhabilitados.';
      return;
    }

    // 2. Buró específico → NO APTO
    final buron = estadoBuro.toUpperCase().trim();
    if (buron == 'PERDIDA') {
      eligibility = 'NO APTO';
      score = 20;
      risk = 'Alto';
      motivoPreEvaluacion = 'Buró: Pérdida.';
      return;
    }

    if (buron == 'DUDOSO' && diasMayorMora >= 90) {
      eligibility = 'NO APTO';
      score = 20;
      risk = 'Alto';
      motivoPreEvaluacion = 'Buró: Dudoso con mora ≥ 90 días.';
      return;
    }

    // 3. Capacidad insuficiente → NO APTO
    if (monthlyIncome <= 0 || availableCapacity <= 0) {
      eligibility = 'NO APTO';
      score = 30;
      risk = 'Alto';
      motivoPreEvaluacion = 'Capacidad de pago insuficiente.';
      return;
    }

    // 4. Ratio excedido → NO APTO
    if (capacityRatio > 0.60) {
      eligibility = 'NO APTO';
      score = 30;
      risk = 'Alto';
      motivoPreEvaluacion = 'Ratio capacidad/cuota excede el límite máximo.';
      return;
    }

    // 5. Buró con observaciones → OBSERVADO o APTO con riesgo
    if (buron == 'CPP' || buron == 'DEFICIENTE') {
      if (capacityRatio <= 0.40) {
        eligibility = 'OBSERVADO';
        score = 55;
        risk = 'Medio';
        motivoPreEvaluacion = 'Buró reporta observaciones. Capacidad adecuada.';
      } else {
        eligibility = 'OBSERVADO';
        score = 50;
        risk = 'Medio';
        motivoPreEvaluacion = 'Buró reporta observaciones y ratio elevado.';
      }
      return;
    }

    // 6. Normal bureau
    if (capacityRatio <= 0.40) {
      eligibility = 'APTO';
      score = 85;
      risk = 'Bajo';
      motivoPreEvaluacion = 'Capacidad de pago adecuada y buró normal.';
    } else if (capacityRatio <= 0.60) {
      eligibility = 'OBSERVADO';
      score = 60;
      risk = 'Medio';
      motivoPreEvaluacion = 'Ratio de capacidad en nivel de observación.';
    } else {
      eligibility = 'NO APTO';
      score = 30;
      risk = 'Alto';
      motivoPreEvaluacion = 'Ratio capacidad/cuota excede el límite máximo.';
    }
  }

  void _generateSchedule(double monto, int plazo) {
    debugPrint('[CLIENT_LOAN] generating schedule rows=$plazo');
    schedule = [];
    double saldo = monto;
    final hoy = DateTime.now();

    for (var i = 1; i <= plazo; i++) {
      final interes = saldo * tem;
      final capital = estimatedInstallment - interes;
      saldo -= capital;
      if (saldo < 0) saldo = 0;

      final fechaPago = DateTime(hoy.year, hoy.month + i, hoy.day);
      schedule.add({
        'numero_cuota': i,
        'fecha_pago': fechaPago.toIso8601String(),
        'cuota': estimatedInstallment,
        'capital': capital,
        'interes': interes,
        'saldo': saldo,
      });
    }
  }

  void _resetComputed() {
    estimatedInstallment = 0;
    totalToPay = 0;
    availableCapacity = 0;
    capacityRatio = 0;
    eligibility = '';
    score = 0;
    risk = '';
    motivoPreEvaluacion = '';
    schedule = [];
  }

  void notifyAll() {
    notifyListeners();
  }
}
