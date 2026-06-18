import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/session/session_timeout_manager.dart';
import '../data/demo_client_data.dart';
import '../model/account_model.dart';
import '../model/credit_model.dart';
import '../model/movement_model.dart';
import '../repository/accounts_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/credits_repository.dart';
import '../repository/profile_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    AccountsRepository? accountsRepository,
    CreditsRepository? creditsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _accountsRepository = accountsRepository ?? AccountsRepository(),
        _creditsRepository = creditsRepository ?? CreditsRepository() {
    _startLoading();
  }

  final AuthRepository _auth;
  final ProfileRepository _profileRepository;
  final AccountsRepository _accountsRepository;
  final CreditsRepository _creditsRepository;

  String clientName = '';
  AccountModel? savingsAccount;
  CreditModel? activeCredit;
  List<MovementModel> recentMovements = [];

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
      debugPrint('[HOME] fallback demo reason=no_session');
      _applyDemoFallback();
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await _profileRepository.getCurrentProfile();
      final account = await _accountsRepository.getMainAccount();
      final credit = await _creditsRepository.getActiveCredit();
      final movements = await _accountsRepository.getMovements();

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

      usingSupabaseData = true;
      loadError = null;
      debugPrint('[HOME] loaded real data');
    } catch (e) {
      debugPrint('[HOME] fallback demo reason=supabase_error');
      _applyDemoFallback();
      loadError = 'No se pudieron cargar los datos remotos.';
      debugPrint('[HomeViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyDemoFallback() {
    clientName = DemoClientData.clientName;
    savingsAccount = DemoClientData.savingsAccount;
    activeCredit = DemoClientData.activeCredit;
    recentMovements = DemoClientData.homeMovements;
  }

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
