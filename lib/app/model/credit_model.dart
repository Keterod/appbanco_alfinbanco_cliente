import '../repository/supabase_parse_utils.dart';

class CreditModel {
  const CreditModel({
    required this.productName,
    required this.pendingAmount,
    required this.nextPaymentDate,
    this.id,
    this.monthlyInstallment,
    this.teaPercent,
    this.paymentProgress,
  });

  final String? id;
  final String productName;
  final double pendingAmount;
  final DateTime nextPaymentDate;
  final double? monthlyInstallment;
  final double? teaPercent;
  final double? paymentProgress;

  factory CreditModel.fromSupabase(Map<String, dynamic> json) {
    final nextDate = parseSupabaseDate(
          json['fecha_proximo_pago'] ?? json['fechaProximoPago'],
        ) ??
        DateTime.now();

    return CreditModel(
      id: parseSupabaseString(json['id']),
      productName: parseSupabaseString(
        json['nombre_producto'] ?? json['nombreProducto'],
        'Préstamo',
      ),
      pendingAmount: parseSupabaseDouble(
        json['monto_pendiente'] ?? json['montoPendiente'],
      ),
      nextPaymentDate: nextDate,
      monthlyInstallment: json.containsKey('cuota_mensual')
          ? parseSupabaseDouble(json['cuota_mensual'])
          : null,
      teaPercent:
          json.containsKey('tea') ? parseSupabaseDouble(json['tea']) : null,
      paymentProgress: json.containsKey('progreso_pago')
          ? parseSupabaseDouble(json['progreso_pago'])
          : null,
    );
  }
}
