import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_client_data.dart';
import '../model/credit_model.dart';
import '../model/payment_schedule_model.dart';
import '../repository/auth_repository.dart';
import '../repository/credits_repository.dart';

class CreditsViewModel extends ChangeNotifier {
  CreditsViewModel({
    AuthRepository? authRepository,
    CreditsRepository? creditsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _creditsRepository = creditsRepository ?? CreditsRepository() {
    _loadDemoData();
    unawaited(_loadFromSupabase());
  }

  final AuthRepository _auth;
  final CreditsRepository _creditsRepository;

  late CreditModel activeCredit;
  late double monthlyInstallment;
  late double teaPercent;
  late double paymentProgress;
  late List<PaymentScheduleModel> schedule;

  bool usingSupabaseData = false;

  void _loadDemoData() {
    activeCredit = DemoClientData.activeCredit;
    monthlyInstallment = DemoClientData.monthlyInstallment;
    teaPercent = DemoClientData.teaPercent;
    paymentProgress = DemoClientData.paymentProgress;
    schedule = DemoClientData.creditSchedule;
  }

  Future<void> _loadFromSupabase() async {
    if (!_auth.isConfigured || _auth.currentUser == null) return;

    try {
      final creditRow = await _creditsRepository.getActiveCreditRow();
      final credit = await _creditsRepository.getActiveCredit();

      if (credit != null) {
        activeCredit = credit;
        monthlyInstallment =
            credit.monthlyInstallment ?? DemoClientData.monthlyInstallment;
        teaPercent = credit.teaPercent ?? DemoClientData.teaPercent;
        paymentProgress =
            credit.paymentProgress ?? DemoClientData.paymentProgress;
      }

      final creditoId = creditRow?['id']?.toString();
      final scheduleRows =
          await _creditsRepository.getPaymentSchedule(creditoId: creditoId);

      if (scheduleRows.isNotEmpty) {
        schedule = scheduleRows;
      }

      usingSupabaseData = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[CreditsViewModel] $e');
    }
  }
}
