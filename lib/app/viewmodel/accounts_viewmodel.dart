import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_client_data.dart';
import '../model/account_model.dart';
import '../model/movement_model.dart';
import '../repository/accounts_repository.dart';
import '../repository/auth_repository.dart';

class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel({
    AuthRepository? authRepository,
    AccountsRepository? accountsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _accountsRepository = accountsRepository ?? AccountsRepository() {
    _startLoading();
  }

  final AuthRepository _auth;
  final AccountsRepository _accountsRepository;

  AccountModel? primaryAccount;
  String cci = '';
  double availableBalance = 0;
  double accountingBalance = 0;
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
    debugPrint('[ACCOUNTS] loading real account');

    if (!_auth.isConfigured || _auth.currentUser == null) {
      debugPrint('[ACCOUNTS] fallback demo reason=no_session');
      _applyDemoFallback();
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final account = await _accountsRepository.getMainAccount();
      final movements = await _accountsRepository.getMovements();

      if (account != null) {
        primaryAccount = account;
        cci = account.cci ?? '';
        availableBalance = account.availableBalance ?? account.balance;
        accountingBalance = account.accountingBalance ?? account.balance;
        debugPrint('[ACCOUNTS] loaded real account');
      }

      if (movements.isNotEmpty) {
        recentMovements = movements;
        debugPrint('[ACCOUNTS] loaded movements=${movements.length}');
      }

      usingSupabaseData = true;
      loadError = null;
    } catch (e) {
      debugPrint('[ACCOUNTS] fallback demo reason=supabase_error');
      _applyDemoFallback();
      loadError = 'No se pudieron cargar los datos.';
      debugPrint('[AccountsViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _applyDemoFallback() {
    primaryAccount = DemoClientData.savingsAccount;
    cci = DemoClientData.cci;
    availableBalance = DemoClientData.savingsAccount.balance;
    accountingBalance = DemoClientData.savingsAccount.balance;
    recentMovements = DemoClientData.accountMovements;
  }
}
