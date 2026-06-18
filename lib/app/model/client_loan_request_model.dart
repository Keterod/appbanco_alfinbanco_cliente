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

  String businessType = businessTypes.first;
  String businessName = '';
  String businessAgeText = '';
  String incomeText = '';
  String expenseText = '';
  String loanAmountText = '';
  int loanTerm = terms.first;
  String loanPurpose = purposes.first;
  String guarantee = guarantees.first;
  bool hasInsurance = true;

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
  List<Map<String, dynamic>> schedule = [];

  bool get canCompute =>
      (double.tryParse(incomeText.replaceAll(',', '.')) ?? 0) > 0 &&
      (double.tryParse(loanAmountText.replaceAll(',', '.')) ?? 0) > 0;

  void compute() {
    monthlyIncome = double.tryParse(incomeText.replaceAll(',', '.')) ?? 0;
    monthlyExpenses = double.tryParse(expenseText.replaceAll(',', '.')) ?? 0;
    final monto = double.tryParse(loanAmountText.replaceAll(',', '.')) ?? 0;
    final plazo = loanTerm;

    if (monto <= 0 || plazo <= 0) {
      estimatedInstallment = 0;
      totalToPay = 0;
      availableCapacity = 0;
      capacityRatio = 0;
      eligibility = '';
      score = 0;
      risk = '';
      schedule = [];
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

    _evaluate();

    _generateSchedule(monto, plazo);
  }

  void _evaluate() {
    if (monthlyIncome <= 0 || availableCapacity <= 0) {
      eligibility = 'NO APTO';
      score = 30;
      risk = 'Alto';
    } else if (capacityRatio <= 0.40) {
      eligibility = 'APTO';
      score = 85;
      risk = 'Bajo';
    } else if (capacityRatio <= 0.60) {
      eligibility = 'OBSERVADO';
      score = 60;
      risk = 'Medio';
    } else {
      eligibility = 'NO APTO';
      score = 30;
      risk = 'Alto';
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

  void notifyAll() {
    notifyListeners();
  }
}
