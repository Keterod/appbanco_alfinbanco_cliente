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

  static int _operationCounter = 1;

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

  Future<void> _loadOriginAccount() async {
    if (!_auth.isConfigured || _auth.currentUser == null) return;
    try {
      final account = await _accountsRepository.getMainAccount();
      if (account != null) {
        originAccount = account.accountNumber;
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
        completedTransfer = await _operationsRepository.createOperation(
          originAccount: originAccount,
          destinationAccount: destination,
          amount: amount,
          description: desc,
          tipoOperacion: operationTypeLabel,
        );
        isLoading = false;
        step = TransferFlowStep.success;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[TransfersViewModel] createOperation: $e');
        generalError =
            'No se pudo registrar la operación. Se usará modo demostración.';
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final opNumber =
        'ALF-OP-${_operationCounter.toString().padLeft(4, '0')}';
    _operationCounter++;

    completedTransfer = TransferModel(
      originAccount: originAccount,
      destinationAccount: destination,
      amount: amount,
      description: desc,
      operationNumber: opNumber,
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
