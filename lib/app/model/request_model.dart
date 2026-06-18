import 'dart:convert';

import '../repository/supabase_parse_utils.dart';

class RequestScheduleRow {
  const RequestScheduleRow({
    required this.numeroCuota,
    this.fechaPago,
    required this.capital,
    required this.interes,
    required this.cuota,
    required this.saldo,
  });

  final int numeroCuota;
  final DateTime? fechaPago;
  final double capital;
  final double interes;
  final double cuota;
  final double saldo;

  factory RequestScheduleRow.fromJson(Map<String, dynamic> json) {
    return RequestScheduleRow(
      numeroCuota: (json['numeroCuota'] ?? json['numero_cuota'] ?? 0) as int,
      fechaPago: parseSupabaseDate(json['fechaPago'] ?? json['fecha_pago']),
      capital: parseSupabaseDouble(json['capital']),
      interes: parseSupabaseDouble(json['interes']),
      cuota: parseSupabaseDouble(json['cuota']),
      saldo: parseSupabaseDouble(json['saldo']),
    );
  }
}

class RequestModel {
  const RequestModel({
    required this.id,
    required this.numeroExpediente,
    required this.estado,
    required this.montoSolicitado,
    required this.plazoMeses,
    required this.cuotaEstimada,
    this.elegibilidad,
    this.scorePreEvaluacion,
    this.ratioCapacidadPago,
    this.riesgoAsignado,
    this.cronograma = const [],
    this.createdAt,
  });

  final String id;
  final String numeroExpediente;
  final String estado;
  final double montoSolicitado;
  final int plazoMeses;
  final double cuotaEstimada;
  final String? elegibilidad;
  final int? scorePreEvaluacion;
  final double? ratioCapacidadPago;
  final String? riesgoAsignado;
  final List<RequestScheduleRow> cronograma;
  final DateTime? createdAt;

  factory RequestModel.fromSupabase(Map<String, dynamic> json) {
    final cronogramaRaw = json['cronograma_json'] ?? json['cronogramaJson'];
    List<RequestScheduleRow> cronograma = [];
    if (cronogramaRaw != null) {
      if (cronogramaRaw is List) {
        cronograma = cronogramaRaw
            .map((e) => RequestScheduleRow.fromJson(
                e is Map<String, dynamic> ? e : {}))
            .toList();
      } else if (cronogramaRaw is String && cronogramaRaw.isNotEmpty) {
        try {
          final decoded = _decodeJson(cronogramaRaw);
          if (decoded is List) {
            cronograma = decoded
                .map((e) => RequestScheduleRow.fromJson(
                    e is Map<String, dynamic> ? e : {}))
                .toList();
          }
        } catch (_) {}
      }
    }

    return RequestModel(
      id: parseSupabaseString(json['id']),
      numeroExpediente: parseSupabaseString(
        json['numero_expediente'] ?? json['numeroExpediente'],
      ),
      estado: parseSupabaseString(json['estado'], 'pendiente'),
      montoSolicitado: parseSupabaseDouble(
        json['monto_solicitado'] ?? json['montoSolicitado'],
      ),
      plazoMeses: (json['plazo_meses'] ?? json['plazoMeses'] ?? 0) as int,
      cuotaEstimada: parseSupabaseDouble(
        json['cuota_estimada'] ?? json['cuotaEstimada'],
      ),
      elegibilidad: json['elegibilidad'] != null
          ? parseSupabaseString(json['elegibilidad'])
          : null,
      scorePreEvaluacion: (json['score_pre_evaluacion'] as num?)?.toInt() ??
          (json['scorePreEvaluacion'] as num?)?.toInt(),
      ratioCapacidadPago: json['ratio_capacidad_pago'] != null
          ? parseSupabaseDouble(json['ratio_capacidad_pago'])
          : (json['ratioCapacidadPago'] != null
              ? parseSupabaseDouble(json['ratioCapacidadPago'])
              : null),
      riesgoAsignado: json['riesgo_asignado'] != null
          ? parseSupabaseString(json['riesgo_asignado'])
          : (json['riesgoAsignado'] != null
              ? parseSupabaseString(json['riesgoAsignado'])
              : null),
      cronograma: cronograma,
      createdAt: parseSupabaseDate(
        json['created_at'] ?? json['createdAt'],
      ),
    );
  }

  static dynamic _decodeJson(String raw) {
    return jsonDecode(raw);
  }
}
