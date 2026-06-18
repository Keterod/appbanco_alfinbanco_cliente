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
    _loadDemoData();
    unawaited(_loadFromSupabase());
  }

  final AuthRepository _auth;
  final AccountsRepository _accountsRepository;

  late AccountModel primaryAccount;
  late String cci;
  late double availableBalance;
  late double accountingBalance;
  late List<MovementModel> recentMovements;

  bool usingSupabaseData = false;

  void _loadDemoData() {
    primaryAccount = DemoClientData.savingsAccount;
    cci = DemoClientData.cci;
    availableBalance = DemoClientData.savingsAccount.balance;
    accountingBalance = DemoClientData.savingsAccount.balance;
    recentMovements = DemoClientData.accountMovements;
  }

  Future<void> _loadFromSupabase() async {
    if (!_auth.isConfigured || _auth.currentUser == null) return;

    try {
      final account = await _accountsRepository.getMainAccount();
      final movements = await _accountsRepository.getMovements();

      if (account != null) {
        primaryAccount = account;
        cci = account.cci?.isNotEmpty == true
            ? account.cci!
            : DemoClientData.cci;
        availableBalance =
            account.availableBalance ?? account.balance;
        accountingBalance =
            account.accountingBalance ?? account.balance;
      }

      if (movements.isNotEmpty) {
        recentMovements = movements;
      }

      usingSupabaseData = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AccountsViewModel] $e');
    }
  }
}
