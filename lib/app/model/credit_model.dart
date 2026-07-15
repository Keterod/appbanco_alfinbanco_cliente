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
    this.montoOriginal,
    this.estado,
    this.isActive,
  });

  final String? id;
  final String productName;
  final double pendingAmount;
  final DateTime nextPaymentDate;
  final double? monthlyInstallment;
  final double? teaPercent;
  final double? paymentProgress;
  final double? montoOriginal;
  final String? estado;
  final bool? isActive;

  factory CreditModel.fromSupabase(Map<String, dynamic> json) {
    final nextDate = parseSupabaseDate(
          json['proxima_fecha_pago'] ??
              json['fecha_proximo_pago'] ??
              json['fechaProximoPago'],
        ) ??
        DateTime.now();

    final rawProgress = json.containsKey('progreso_pago')
        ? parseSupabaseDouble(json['progreso_pago'])
        : null;

    return CreditModel(
      id: parseSupabaseString(json['id']),
      productName: parseSupabaseString(
        json['nombre_producto'] ?? json['producto'] ?? json['nombreProducto'],
        'Crédito Empresarial Alfin',
      ),
      pendingAmount: parseSupabaseDouble(
        json['monto_pendiente'] ?? json['montoPendiente'],
      ),
      nextPaymentDate: nextDate,
      monthlyInstallment: json.containsKey('cuota_mensual')
          ? parseSupabaseDouble(json['cuota_mensual'])
          : null,
      teaPercent: json.containsKey('tea_referencial')
          ? parseSupabaseDouble(json['tea_referencial'])
          : json.containsKey('tea')
              ? parseSupabaseDouble(json['tea'])
              : null,
      paymentProgress: rawProgress,
      montoOriginal: json.containsKey('monto_original')
          ? parseSupabaseDouble(json['monto_original'])
          : null,
      estado: json.containsKey('estado')
          ? parseSupabaseString(json['estado'])
          : null,
      isActive: json['activo'] == true,
    );
  }
}
