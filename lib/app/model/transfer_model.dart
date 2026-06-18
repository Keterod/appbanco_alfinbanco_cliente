import '../repository/supabase_parse_utils.dart';

class TransferModel {
  const TransferModel({
    required this.originAccount,
    required this.destinationAccount,
    required this.amount,
    required this.description,
    required this.operationNumber,
    required this.date,
    required this.status,
  });

  final String originAccount;
  final String destinationAccount;
  final double amount;
  final String description;
  final String operationNumber;
  final DateTime date;
  final String status;

  factory TransferModel.fromSupabase(
    Map<String, dynamic> json, {
    String? fallbackOrigin,
    String? fallbackDestination,
  }) {
    return TransferModel(
      originAccount: parseSupabaseString(
        json['cuenta_origen'] ?? json['cuentaOrigen'],
        fallbackOrigin ?? '',
      ),
      destinationAccount: parseSupabaseString(
        json['cuenta_destino'] ?? json['cuentaDestino'],
        fallbackDestination ?? '',
      ),
      amount: parseSupabaseDouble(json['monto']),
      description: parseSupabaseString(json['descripcion']),
      operationNumber: parseSupabaseString(json['numero_operacion']),
      date: parseSupabaseDate(json['fecha']) ?? DateTime.now(),
      status: parseSupabaseString(json['estado'], 'Completada'),
    );
  }
}
