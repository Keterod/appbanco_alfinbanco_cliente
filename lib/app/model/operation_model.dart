import '../repository/supabase_parse_utils.dart';

class OperationModel {
  const OperationModel({
    required this.id,
    required this.clienteId,
    required this.cuentaOrigen,
    required this.cuentaDestino,
    required this.monto,
    required this.descripcion,
    required this.numeroOperacion,
    required this.fecha,
    required this.estado,
    required this.tipoOperacion,
  });

  final String id;
  final String clienteId;
  final String cuentaOrigen;
  final String cuentaDestino;
  final double monto;
  final String descripcion;
  final String numeroOperacion;
  final DateTime fecha;
  final String estado;
  final String tipoOperacion;

  factory OperationModel.fromSupabase(Map<String, dynamic> json) {
    return OperationModel(
      id: parseSupabaseString(json['id'], ''),
      clienteId: parseSupabaseString(json['cliente_id'], ''),
      cuentaOrigen: parseSupabaseString(json['cuenta_origen']),
      cuentaDestino: parseSupabaseString(json['cuenta_destino']),
      monto: parseSupabaseDouble(json['monto']),
      descripcion: parseSupabaseString(json['descripcion']),
      numeroOperacion: parseSupabaseString(json['numero_operacion']),
      fecha: parseSupabaseDate(json['fecha']) ?? DateTime.now(),
      estado: parseSupabaseString(json['estado'], 'Completada'),
      tipoOperacion: parseSupabaseString(json['tipo_operacion']),
    );
  }
}
