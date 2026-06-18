import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_client_data.dart';
import '../model/credit_model.dart';
import '../model/payment_schedule_model.dart';
import '../repository/auth_repository.dart';
import '../repository/credits_repository.dart';
import '../repository/disbursement_repository.dart';

class CreditsViewModel extends ChangeNotifier {
  CreditsViewModel({
    AuthRepository? authRepository,
    CreditsRepository? creditsRepository,
    DisbursementRepository? disbursementRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _creditsRepository = creditsRepository ?? CreditsRepository(),
        _disbursementRepository =
            disbursementRepository ?? DisbursementRepository() {
    _startLoading();
  }

  final AuthRepository _auth;
  final CreditsRepository _creditsRepository;
  final DisbursementRepository _disbursementRepository;

  CreditModel? activeCredit;
  double monthlyInstallment = 0;
  double teaPercent = 0;
  double paymentProgress = 0;
  List<PaymentScheduleModel> schedule = [];

  bool isLoading = true;
  bool usingSupabaseData = false;
  String? loadError;

  void _startLoading() {
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    unawaited(_loadFromSupabase());
  }

  Future<void> _loadFromSupabase() async {
    debugPrint('[CREDITS] loading real credit');

    if (!_auth.isConfigured || _auth.currentUser == null) {
      debugPrint('[CREDITS] fallback demo reason=no_session');
      _applyDemoFallback();
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      try {
        await _disbursementRepository.reflectDisbursedRequests();
      } catch (e) {
        debugPrint('[CREDITS] disbursement reflection error: $e');
      }

      final creditRow = await _creditsRepository.getActiveCreditRow();
      final credit = await _creditsRepository.getActiveCredit();

      if (credit != null) {
        activeCredit = credit;
        monthlyInstallment = credit.monthlyInstallment ?? 0;
        teaPercent = credit.teaPercent ?? 0;
        paymentProgress = credit.paymentProgress ?? 0;
        debugPrint('[CREDITS] loaded real credit');
      }

      final creditoId = creditRow?['id']?.toString();
      final scheduleRows =
          await _creditsRepository.getPaymentSchedule(creditoId: creditoId);

      if (scheduleRows.isNotEmpty) {
        schedule = scheduleRows;
        debugPrint('[CREDITS] loaded schedule=${scheduleRows.length}');
      }

      usingSupabaseData = true;
      loadError = null;
    } catch (e) {
      debugPrint('[CREDITS] fallback demo reason=supabase_error');
      _applyDemoFallback();
      loadError = 'No se pudieron cargar los datos.';
      debugPrint('[CreditsViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyDemoFallback() {
    activeCredit = DemoClientData.activeCredit;
    monthlyInstallment = DemoClientData.monthlyInstallment;
    teaPercent = DemoClientData.teaPercent;
    paymentProgress = DemoClientData.paymentProgress;
    schedule = DemoClientData.creditSchedule;
  }
}
