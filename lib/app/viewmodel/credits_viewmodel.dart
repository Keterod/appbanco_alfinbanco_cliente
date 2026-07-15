import 'dart:async';

import 'package:flutter/foundation.dart';

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
    _startLoading();
  }

  final AuthRepository _auth;
  final CreditsRepository _creditsRepository;

  List<CreditModel> credits = [];
  List<PaymentScheduleModel> schedule = [];

  bool isLoading = true;
  bool usingSupabaseData = false;
  String? loadError;

  CreditModel? get activeCredit => credits.isNotEmpty ? credits.first : null;

  void _startLoading() {
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    unawaited(_loadFromSupabase());
  }

  Future<void> _loadFromSupabase() async {
    debugPrint('[CREDITS] loading real credits');

    if (!_auth.isConfigured || _auth.currentUser == null) {
      debugPrint('[CREDITS] no session, return empty');
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      credits = await _creditsRepository.getCredits();
      debugPrint('[CREDITS] loaded credits count=${credits.length}');

      if (credits.isNotEmpty) {
        final credit = credits.first;
        debugPrint('[CREDITS] showing first credit: ${credit.productName}');
      }

      if (credits.isNotEmpty) {
        final scheduleRows = await _creditsRepository.getPaymentSchedule(
          creditoId: credits.first.id,
        );
        if (scheduleRows.isNotEmpty) {
          schedule = scheduleRows;
          debugPrint('[CREDITS] loaded schedule=${scheduleRows.length}');
        }
      }

      usingSupabaseData = true;
      loadError = null;
    } catch (e) {
      debugPrint('[CREDITS] error loading: $e');
      loadError = 'No se pudieron cargar los datos.';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    credits = [];
    schedule = [];
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    notifyListeners();
    await _loadFromSupabase();
  }
}
