import 'package:flutter/foundation.dart';

import '../model/account_model.dart';
import '../model/credit_model.dart';

/// Movimiento mostrado en dashboard (dato de presentación, S9).
class MovementItem {
  const MovementItem({
    required this.description,
    required this.dateLabel,
    required this.amount,
    this.isCredit = false,
  });

  final String description;
  final String dateLabel;
  final double amount;
  final bool isCredit;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    _loadDemoData();
  }

  late String clientName;
  late AccountModel savingsAccount;
  late CreditModel activeCredit;
  late List<MovementItem> recentMovements;

  void _loadDemoData() {
    clientName = 'Diego';
    savingsAccount = const AccountModel(
      accountNumber: '0011-0456-7890123456',
      accountType: 'Cuenta de ahorros',
      balance: 2450.80,
    );
    activeCredit = CreditModel(
      productName: 'Préstamo personal',
      pendingAmount: 5800.00,
      nextPaymentDate: DateTime(2026, 5, 28),
    );
    recentMovements = const [
      MovementItem(
        description: 'Transferencia recibida',
        dateLabel: '12 may 2026',
        amount: 350.00,
        isCredit: true,
      ),
      MovementItem(
        description: 'Pago con tarjeta — Supermercado',
        dateLabel: '10 may 2026',
        amount: -128.40,
      ),
      MovementItem(
        description: 'Cargo automático — servicios',
        dateLabel: '08 may 2026',
        amount: -89.90,
      ),
    ];
  }

  static String formatSoles(double value) {
    final sign = value < 0 ? '-' : '';
    final fixed = value.abs().toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final intPart = fixed.substring(0, dot);
    final dec = fixed.substring(dot + 1);
    final rev = intPart.split('').reversed.join();
    final buf = StringBuffer();
    for (var i = 0; i < rev.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(rev[i]);
    }
    final intFormatted = buf.toString().split('').reversed.join();
    return '$sign$intFormatted.$dec';
  }
}
