import 'dart:async';

import 'package:flutter/foundation.dart';

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

  List<AccountModel> accounts = [];
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
      debugPrint('[ACCOUNTS] no session');
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final loadedAccounts = await _accountsRepository.getAccounts();
      final movements = await _accountsRepository.getMovements();

      if (loadedAccounts.isNotEmpty) {
        accounts = loadedAccounts;
        primaryAccount = loadedAccounts.firstWhere(
          (a) => a.isPrincipal,
          orElse: () => loadedAccounts.first,
        );
        cci = primaryAccount!.cci ?? '';
        availableBalance = primaryAccount!.availableBalance ?? primaryAccount!.balance;
        accountingBalance = primaryAccount!.accountingBalance ?? primaryAccount!.balance;
        debugPrint('[ACCOUNTS] loaded accounts=${loadedAccounts.length}');
      }

      if (movements.isNotEmpty) {
        recentMovements = movements;
        debugPrint('[ACCOUNTS] loaded movements=${movements.length}');
      }

      usingSupabaseData = true;
      loadError = null;
    } catch (e) {
      debugPrint('[ACCOUNTS] error=$e');
      loadError = 'No se pudieron cargar los datos.';
    }

    isLoading = false;
    notifyListeners();
  }
}
