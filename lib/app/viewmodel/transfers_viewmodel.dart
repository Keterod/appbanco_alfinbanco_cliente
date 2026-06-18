import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/transfer_model.dart';
import '../repository/accounts_repository.dart';
import '../repository/auth_repository.dart';
import '../repository/operations_repository.dart';

enum TransferOperationType {
  transferencia,
  pagoCredito,
  pagoServicio,
}

enum TransferFlowStep { form, summary, success }

class TransfersViewModel extends ChangeNotifier {
  TransfersViewModel({
    this.initialOperationType,
    AuthRepository? authRepository,
    AccountsRepository? accountsRepository,
    OperationsRepository? operationsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _accountsRepository = accountsRepository ?? AccountsRepository(),
        _operationsRepository =
            operationsRepository ?? OperationsRepository();

  final TransferOperationType? initialOperationType;

  final AuthRepository _auth;
  final AccountsRepository _accountsRepository;
  final OperationsRepository _operationsRepository;

  TransferFlowStep step = TransferFlowStep.form;
  TransferOperationType operationType = TransferOperationType.transferencia;

  String originAccount = '0011-0456-7890123456';
  String destinationAccount = '';
  String amountText = '';
  String description = '';

  String? destinationError;
  String? amountError;
  String? generalError;

  bool isLoading = false;
  TransferModel? completedTransfer;

  double _availableBalance = 0;
  bool _balanceLoaded = false;

  void init() {
    if (initialOperationType != null) {
      operationType = initialOperationType!;
      if (operationType == TransferOperationType.pagoCredito) {
        destinationAccount = 'Préstamo personal — cuota 5';
        amountText = '485.50';
        description = 'Pago de cuota de crédito';
      }
    }
    unawaited(_loadOriginAccount());
    notifyListeners();
  }

  String get _operationCategory {
    return switch (operationType) {
      TransferOperationType.transferencia => 'Transferencia',
      TransferOperationType.pagoCredito => 'Pago de crédito',
      TransferOperationType.pagoServicio => 'Servicios',
    };
  }

  Future<void> _loadOriginAccount() async {
    if (!_auth.isConfigured || _auth.currentUser == null) return;
    try {
      final account = await _accountsRepository.getMainAccount();
      if (account != null) {
        originAccount = account.accountNumber;
        _availableBalance = account.balance;
        _balanceLoaded = true;
        debugPrint('[TRANSFERS] loading real account');
        debugPrint('[TRANSFERS] balance=$_availableBalance');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[TransfersViewModel] $e');
    }
  }

  void setOperationType(TransferOperationType type) {
    operationType = type;
    destinationError = null;
    generalError = null;
    if (type == TransferOperationType.pagoCredito) {
      destinationAccount = 'Préstamo personal — cuota 5';
      amountText = '485.50';
    } else if (type == TransferOperationType.pagoServicio) {
      destinationAccount = 'Servicio: Luz del Sur';
      amountText = '';
    } else {
      destinationAccount = '';
      amountText = '';
    }
    notifyListeners();
  }

  void setDestination(String value) {
    destinationAccount = value;
    notifyListeners();
  }

  void setAmount(String value) {
    amountText = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  bool validateForContinue() {
    destinationError = null;
    amountError = null;
    generalError = null;

    if (operationType == TransferOperationType.transferencia &&
        destinationAccount.trim().isEmpty) {
      destinationError = 'Ingrese la cuenta destino';
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      amountError = 'Ingrese un monto mayor a 0';
    } else if (_balanceLoaded && amount > _availableBalance) {
      amountError = 'Saldo insuficiente para realizar la operación.';
    }

    final valid = destinationError == null && amountError == null;
    if (!valid) notifyListeners();
    return valid;
  }

  void goToSummary() {
    if (!validateForContinue()) return;
    step = TransferFlowStep.summary;
    notifyListeners();
  }

  void goBackToForm() {
    step = TransferFlowStep.form;
    notifyListeners();
  }

  Future<void> confirmOperation() async {
    if (!validateForContinue()) return;
    isLoading = true;
    generalError = null;
    notifyListeners();

    final amount = double.parse(amountText.replaceAll(',', '.'));
    final desc = description.trim().isEmpty
        ? _defaultDescription()
        : description.trim();
    final destination = destinationAccount.trim();

    if (_auth.isConfigured && _auth.currentUser != null) {
      try {
        debugPrint('[TRANSFERS] validating funds');
        if (_balanceLoaded && amount > _availableBalance) {
          generalError = 'Saldo insuficiente para realizar la operación.';
          isLoading = false;
          notifyListeners();
          return;
        }

        debugPrint('[TRANSFERS] inserting operation');
        completedTransfer = await _operationsRepository.createOperation(
          originAccount: originAccount,
          destinationAccount: destination,
          amount: amount,
          description: desc,
          tipoOperacion: operationTypeLabel,
        );

        debugPrint('[TRANSFERS] inserting movement');
        await _accountsRepository.insertMovement(
          amount: amount,
          description: desc,
          category: _operationCategory,
          reference: completedTransfer!.operationNumber,
          isDebit: true,
        );

        debugPrint('[TRANSFERS] updating balance');
        final newBalance = _availableBalance - amount;
        await _accountsRepository.updateBalance(newBalance);
        _availableBalance = newBalance;

        debugPrint(
            '[TRANSFERS] operation completed numero=${completedTransfer!.operationNumber}');
        isLoading = false;
        step = TransferFlowStep.success;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[TRANSFERS] error=$e');
        generalError = 'No se pudo completar la operación. Intente nuevamente.';
        isLoading = false;
        notifyListeners();
        return;
      }
    }

    completedTransfer = TransferModel(
      originAccount: originAccount,
      destinationAccount: destination,
      amount: amount,
      description: desc,
      operationNumber: 'ALF-OP-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      status: 'Completada',
    );

    isLoading = false;
    step = TransferFlowStep.success;
    notifyListeners();
  }

  String _defaultDescription() {
    return switch (operationType) {
      TransferOperationType.transferencia => 'Transferencia entre cuentas',
      TransferOperationType.pagoCredito => 'Pago de cuota de crédito',
      TransferOperationType.pagoServicio => 'Pago de servicio',
    };
  }

  String get operationTypeLabel {
    return switch (operationType) {
      TransferOperationType.transferencia => 'Transferencia',
      TransferOperationType.pagoCredito => 'Pago de crédito',
      TransferOperationType.pagoServicio => 'Pago de servicio',
    };
  }

  void resetForNewOperation() {
    step = TransferFlowStep.form;
    destinationAccount = '';
    amountText = '';
    description = '';
    destinationError = null;
    amountError = null;
    generalError = null;
    completedTransfer = null;
    operationType = TransferOperationType.transferencia;
    notifyListeners();
  }

  double? get parsedAmount {
    return double.tryParse(amountText.replaceAll(',', '.'));
  }
}
