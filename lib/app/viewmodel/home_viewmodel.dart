import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/session/session_timeout_manager.dart';
import '../model/account_model.dart';
import '../model/credit_model.dart';
import '../model/movement_model.dart';
import '../model/request_model.dart';
import '../repository/accounts_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/credits_repository.dart';
import '../repository/profile_repository.dart';
import '../repository/requests_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    AccountsRepository? accountsRepository,
    CreditsRepository? creditsRepository,
    RequestsRepository? requestsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _accountsRepository = accountsRepository ?? AccountsRepository(),
        _creditsRepository = creditsRepository ?? CreditsRepository(),
        _requestsRepository = requestsRepository ?? RequestsRepository() {
    _startLoading();
  }

  final AuthRepository _auth;
  final ProfileRepository _profileRepository;
  final AccountsRepository _accountsRepository;
  final CreditsRepository _creditsRepository;
  final RequestsRepository _requestsRepository;

  String clientName = '';
  AccountModel? savingsAccount;
  CreditModel? activeCredit;
  List<MovementModel> recentMovements = [];
  List<RequestModel> requests = [];
  bool requestsLoaded = false;

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
    debugPrint('[HOME] loading real data');

    if (!_auth.isConfigured || _auth.currentUser == null) {
      debugPrint('[HOME] no session');
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await _profileRepository.getCurrentProfile();
      final account = await _accountsRepository.getMainAccount();
      final credits = await _creditsRepository.getCredits();
      final credit = credits.isNotEmpty ? credits.first : null;
      final movements = await _accountsRepository.getMovements();
      final reqs = await _requestsRepository.getRequests();

      if (profile != null) {
        final parts = profile.fullName.split(' ');
        clientName = parts.isNotEmpty ? parts.first : profile.fullName;
      }

      if (account != null) {
        savingsAccount = account;
      }

      if (credit != null) {
        activeCredit = credit;
      }

      if (movements.isNotEmpty) {
        recentMovements = movements.take(5).toList();
      }

      if (reqs.isNotEmpty) {
        requests = reqs;
        requestsLoaded = true;
      }

      usingSupabaseData = true;
      loadError = null;
      debugPrint('[HOME] loaded real data');
    } catch (e) {
      debugPrint('[HOME] error=$e');
      loadError = 'No se pudieron cargar los datos remotos.';
    }

    isLoading = false;
    notifyListeners();
  }

  int get evaluationCount =>
      requests.where((r) => r.normalizedStatus == 'recibido_comite' || r.normalizedStatus == 'en_evaluacion').length;

  int get approvedCount =>
      requests.where((r) => r.isApproved || r.isDisbursed).length;

  int get rejectedCount =>
      requests.where((r) => r.isRejected).length;

  int get pendingCount =>
      requests.where((r) => r.normalizedStatus == 'enviado').length;

  RequestModel? get latestRequest => requests.isNotEmpty ? requests.first : null;

  Future<void> reload() async {
    clientName = '';
    savingsAccount = null;
    activeCredit = null;
    recentMovements = [];
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    notifyListeners();
    await _loadFromSupabase();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await SessionTimeoutManager.clearActivity();
      debugPrint('[AUTH] logout completed');
    } catch (e) {
      debugPrint('[HomeViewModel] logout error: $e');
    }
  }
}
