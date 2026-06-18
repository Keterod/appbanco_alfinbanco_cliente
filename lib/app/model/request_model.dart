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
    this.observacionEvaluador,
    this.motivoRechazo,
    this.montoAprobado,
    this.fechaDecision,
    this.fechaDesembolso,
    this.canal,
    this.asesorAsignado,
    this.prioridad,
    this.updatedAt,
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
  final String? observacionEvaluador;
  final String? motivoRechazo;
  final double? montoAprobado;
  final DateTime? fechaDecision;
  final DateTime? fechaDesembolso;
  final String? canal;
  final String? asesorAsignado;
  final String? prioridad;
  final DateTime? updatedAt;

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
      observacionEvaluador: parseSupabaseString(
        json['observacion_evaluador'] ?? json['observacionEvaluador'],
      ),
      motivoRechazo: parseSupabaseString(
        json['motivo_rechazo'] ?? json['motivoRechazo'],
      ),
      montoAprobado: json['monto_aprobado'] != null
          ? parseSupabaseDouble(json['monto_aprobado'])
          : (json['montoAprobado'] != null
              ? parseSupabaseDouble(json['montoAprobado'])
              : null),
      fechaDecision: parseSupabaseDate(
        json['fecha_decision'] ?? json['fechaDecision'],
      ),
      fechaDesembolso: parseSupabaseDate(
        json['fecha_desembolso'] ?? json['fechaDesembolso'],
      ),
      canal: parseSupabaseString(json['canal']),
      asesorAsignado: parseSupabaseString(
        json['asesor_asignado'] ?? json['asesorAsignado'],
      ),
      prioridad: parseSupabaseString(json['prioridad']),
      updatedAt: parseSupabaseDate(
        json['updated_at'] ?? json['updatedAt'],
      ),
    );
  }

  static dynamic _decodeJson(String raw) {
    return jsonDecode(raw);
  }

  // --- Status helpers ---

  static const _statusLabels = <String, String>{
    'borrador': 'Borrador',
    'enviado': 'Solicitud enviada',
    'recibido_comite': 'Recibido por comité',
    'en_evaluacion': 'En evaluación',
    'aprobado': 'Aprobado',
    'condicionado': 'Aprobado con condiciones',
    'rechazado': 'Rechazado',
    'desembolsado': 'Desembolsado',
  };

  static const _statusDescriptions = <String, String>{
    'enviado': 'Tu solicitud fue registrada correctamente y está pendiente de revisión.',
    'recibido_comite': 'El expediente fue recibido para evaluación.',
    'en_evaluacion': 'El equipo está revisando tu información crediticia.',
    'aprobado': 'Tu solicitud fue aprobada. Está pendiente de desembolso.',
    'condicionado': 'Tu solicitud fue aprobada con ajustes o condiciones.',
    'rechazado': 'Tu solicitud no fue aprobada.',
    'desembolsado': 'El crédito fue desembolsado y ya forma parte de tus productos.',
  };

  static const _timelineSteps = [
    'Solicitud enviada',
    'Recibido por comité',
    'En evaluación',
    'Decisión',
    'Desembolso',
  ];

  static const _timelineDescriptions = [
    'Tu expediente fue registrado correctamente.',
    'El comité de crédito recibió tu expediente.',
    'Tu información crediticia está siendo evaluada.',
    'El comité emitió una decisión sobre tu solicitud.',
    'El crédito fue desembolsado a tu cuenta.',
  ];

  static const _statusStepIndex = <String, int>{
    'borrador': -1,
    'enviado': 0,
    'recibido_comite': 1,
    'en_evaluacion': 2,
    'aprobado': 3,
    'condicionado': 3,
    'rechazado': 3,
    'desembolsado': 4,
  };

  String get normalizedStatus => estado.toLowerCase().trim();

  String get statusLabel =>
      _statusLabels[normalizedStatus] ?? normalizedStatus;

  String get statusDescription =>
      _statusDescriptions[normalizedStatus] ??
      'Estado: ${_statusLabels[normalizedStatus] ?? normalizedStatus}';

  int get statusStepIndex => _statusStepIndex[normalizedStatus] ?? -1;

  bool get isRejected => normalizedStatus == 'rechazado';
  bool get isApproved => normalizedStatus == 'aprobado' || normalizedStatus == 'condicionado';
  bool get isDisbursed => normalizedStatus == 'desembolsado';
  bool get isConditioned => normalizedStatus == 'condicionado';
  bool get hasDecision =>
      normalizedStatus == 'aprobado' ||
      normalizedStatus == 'condicionado' ||
      normalizedStatus == 'rechazado';
  bool get hasUpdate =>
      updatedAt != null && createdAt != null &&
      updatedAt!.isAfter(createdAt!);

  static String statusLabelFor(String estado) {
    return _statusLabels[estado.toLowerCase().trim()] ?? estado;
  }

  static String statusDescriptionFor(String estado) {
    return _statusDescriptions[estado.toLowerCase().trim()] ??
        _statusLabels[estado.toLowerCase().trim()] ?? estado;
  }

  static int statusStepIndexFor(String estado) {
    return _statusStepIndex[estado.toLowerCase().trim()] ?? -1;
  }

  static List<String> get timelineSteps => _timelineSteps;
  static List<String> get timelineDescriptions => _timelineDescriptions;
  static int get totalSteps => _timelineSteps.length;
}
