import '../repository/supabase_parse_utils.dart';

enum PaymentInstallmentStatus { paid, pending, overdue }

class PaymentScheduleModel {
  const PaymentScheduleModel({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
    this.id,
    this.creditoId,
    this.capital,
    this.interes,
    this.saldo,
  });

  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final PaymentInstallmentStatus status;
  final DateTime? paidDate;
  final String? id;
  final String? creditoId;
  final double? capital;
  final double? interes;
  final double? saldo;

  String get statusLabel {
    switch (status) {
      case PaymentInstallmentStatus.paid:
        return 'Pagado';
      case PaymentInstallmentStatus.pending:
        return 'Pendiente';
      case PaymentInstallmentStatus.overdue:
        return 'Vencido';
    }
  }

  factory PaymentScheduleModel.fromSupabase(Map<String, dynamic> json) {
    return PaymentScheduleModel(
      installmentNumber: (json['numero_cuota'] as num?)?.toInt() ?? 0,
      dueDate: parseSupabaseDate(json['fecha_vencimiento']) ?? DateTime.now(),
      amount: parseSupabaseDouble(json['monto']),
      status: _statusFromString(parseSupabaseString(json['estado'])),
      paidDate: parseSupabaseDate(json['fecha_pago']),
      id: json.containsKey('id') ? parseSupabaseString(json['id']) : null,
      creditoId: json.containsKey('credito_id')
          ? parseSupabaseString(json['credito_id'])
          : null,
      capital: json.containsKey('capital')
          ? parseSupabaseDouble(json['capital'])
          : 0,
      interes: json.containsKey('interes')
          ? parseSupabaseDouble(json['interes'])
          : 0,
      saldo: json.containsKey('saldo')
          ? parseSupabaseDouble(json['saldo'])
          : 0,
    );
  }

  static PaymentInstallmentStatus _statusFromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'pagado' || normalized.contains('pag')) {
      return PaymentInstallmentStatus.paid;
    }
    if (normalized == 'vencido' ||
        normalized.contains('venc') ||
        normalized.contains('overdue')) {
      return PaymentInstallmentStatus.overdue;
    }
    return PaymentInstallmentStatus.pending;
  }
}
