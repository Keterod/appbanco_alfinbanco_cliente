import '../repository/supabase_parse_utils.dart';

class AccountModel {
  const AccountModel({
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    this.cci,
    this.availableBalance,
    this.accountingBalance,
  });

  final String accountNumber;
  final String accountType;
  final double balance;
  final String? cci;
  final double? availableBalance;
  final double? accountingBalance;

  factory AccountModel.fromSupabase(Map<String, dynamic> json) {
    final saldo = parseSupabaseDouble(json['saldo']);
    return AccountModel(
      accountNumber: parseSupabaseString(
        json['numero_cuenta'] ?? json['numeroCuenta'],
      ),
      accountType: parseSupabaseString(
        json['tipo_cuenta'] ?? json['tipoCuenta'],
        'Cuenta de ahorros',
      ),
      balance: saldo,
      cci: parseSupabaseString(json['cci']),
      availableBalance: json.containsKey('saldo_disponible')
          ? parseSupabaseDouble(json['saldo_disponible'])
          : saldo,
      accountingBalance: json.containsKey('saldo_contable')
          ? parseSupabaseDouble(json['saldo_contable'])
          : saldo,
    );
  }
}
