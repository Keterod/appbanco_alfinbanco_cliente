import '../repository/supabase_parse_utils.dart';

enum PaymentInstallmentStatus { paid, pending, overdue }

class PaymentScheduleModel {
  const PaymentScheduleModel({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidDate,
  });

  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final PaymentInstallmentStatus status;
  final DateTime? paidDate;

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
    );
  }

  static PaymentInstallmentStatus _statusFromString(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('pag')) {
      return PaymentInstallmentStatus.paid;
    }
    if (normalized.contains('venc') || normalized.contains('overdue')) {
      return PaymentInstallmentStatus.overdue;
    }
    return PaymentInstallmentStatus.pending;
  }
}
