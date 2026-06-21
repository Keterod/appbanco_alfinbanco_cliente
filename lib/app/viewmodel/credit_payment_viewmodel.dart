import 'package:flutter/foundation.dart';

import '../model/account_model.dart';
import '../model/credit_model.dart';
import '../model/payment_schedule_model.dart';
import '../repository/accounts_repository.dart';
import '../repository/credit_payment_repository.dart';
import '../repository/credits_repository.dart';

class CreditPaymentViewModel extends ChangeNotifier {
  CreditPaymentViewModel({
    CreditsRepository? creditsRepository,
    AccountsRepository? accountsRepository,
    CreditPaymentRepository? paymentRepository,
  })  : _creditsRepository = creditsRepository ?? CreditsRepository(),
        _accountsRepository = accountsRepository ?? AccountsRepository(),
        _paymentRepository = paymentRepository ?? CreditPaymentRepository();

  final CreditsRepository _creditsRepository;
  final AccountsRepository _accountsRepository;
  final CreditPaymentRepository _paymentRepository;

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  CreditModel? credit;
  PaymentScheduleModel? nextInstallment;
  List<AccountModel> availableAccounts = [];
  AccountModel? selectedAccount;
  CreditPaymentResult? paymentResult;

  Future<void> loadData(CreditModel creditParam) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      credit = creditParam;

      final schedule =
          await _creditsRepository.getPaymentSchedule(creditoId: creditParam.id);
      final pending = schedule.where(
        (s) => s.status == PaymentInstallmentStatus.pending,
      );
      nextInstallment = pending.isNotEmpty ? pending.first : null;

      availableAccounts = await _accountsRepository.getAccounts();
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT_VM] loadData error: $e');
      errorMessage = 'No se pudieron cargar los datos.';
    }

    isLoading = false;
    notifyListeners();
  }

  void selectAccount(AccountModel account) {
    selectedAccount = account;
    errorMessage = null;
    notifyListeners();
  }

  String? validate() {
    if (nextInstallment == null) {
      return 'No tienes cuotas pendientes.';
    }
    if (selectedAccount == null) {
      return 'Selecciona una cuenta origen.';
    }
    final available =
        selectedAccount!.availableBalance ?? selectedAccount!.balance;
    if (available < nextInstallment!.amount) {
      return 'Saldo insuficiente para pagar la cuota.';
    }
    return null;
  }

  Future<void> confirmPayment() async {
    final validationError = validate();
    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      paymentResult = await _paymentRepository.payNextInstallment(
        credit: credit!,
        installment: nextInstallment!,
        originAccount: selectedAccount!,
      );
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] error=$e');
      final msg = e.toString();
      if (msg.contains('ya fue pagada')) {
        errorMessage = 'La cuota ya fue pagada.';
      } else if (msg.contains('Saldo insuficiente')) {
        errorMessage = 'Saldo insuficiente para pagar la cuota.';
      } else {
        errorMessage = 'No se pudo registrar el pago.';
      }
    }

    isSubmitting = false;
    notifyListeners();
  }
}
