import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/client_loan_request_model.dart';
import 'auth_repository.dart';

class ClientLoanRequestRepository {
  ClientLoanRequestRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  Future<String?> getClienteId() async {
    debugPrint('[CLIENT_LOAN] loading client bridge');

    if (!_auth.isConfigured) return null;
    final userId = _auth.currentUser?.id;
    if (userId == null) return null;

    final client = _client ?? supabase;

    debugPrint('[CLIENT_LOAN] reading clientes_perfil for userId=$userId');
    final perfilRow = await client
        .from('clientes_perfil')
        .select('dni')
        .eq('id', userId)
        .maybeSingle();

    if (perfilRow == null) {
      debugPrint('[CLIENT_LOAN] clientes_perfil not found');
      return null;
    }

    final perfil = Map<String, dynamic>.from(perfilRow as Map);
    final dni = perfil['dni']?.toString();
    if (dni == null || dni.isEmpty) {
      debugPrint('[CLIENT_LOAN] DNI not found in perfil');
      return null;
    }
    debugPrint('[CLIENT_LOAN] perfil dni=$dni');

    final clienteRow = await client
        .from('clientes')
        .select('id')
        .eq('numero_documento', dni)
        .maybeSingle();

    if (clienteRow == null) {
      debugPrint('[CLIENT_LOAN] clientes not found for DNI=$dni');
      return null;
    }

    final cliente = Map<String, dynamic>.from(clienteRow as Map);
    final clienteId = cliente['id']?.toString();
    debugPrint('[CLIENT_LOAN] cliente_id=$clienteId');
    return clienteId;
  }

  Future<Map<String, dynamic>> submitRequest({
    required String clienteId,
    required ClientLoanRequestModel model,
  }) async {
    debugPrint('[CLIENT_LOAN] inserting request');

    final client = _client ?? supabase;
    final now = DateTime.now();
    final expediente =
        'EXP-ALF-2026-${now.millisecondsSinceEpoch}';
    final monto =
        double.tryParse(model.loanAmountText.replaceAll(',', '.')) ?? 0;
    final ingreso = model.monthlyIncome;
    final gasto = model.monthlyExpenses;
    final antiguedad =
        int.tryParse(model.businessAgeText) ?? 0;

    final data = <String, dynamic>{
      'numero_expediente': expediente,
      'cliente_id': clienteId,
      'monto_solicitado': monto,
      'plazo_meses': model.loanTerm,
      'cuota_estimada': model.estimatedInstallment,
      'cronograma_json': jsonEncode(model.schedule),
      'score_pre_evaluacion': model.score,
      'elegibilidad': model.eligibility,
      'ratio_capacidad_pago': model.capacityRatio,
      'riesgo_asignado': model.risk,
      'estado': 'enviado',
      'tipo_negocio': model.businessType,
      'nombre_negocio': model.businessName,
      'antiguedad_negocio_meses': antiguedad,
      'ingresos_estimados': ingreso,
      'gastos_mensuales': gasto,
      'destino_credito': model.loanPurpose,
      'garantia': model.guarantee,
      'tea_referencial': model.tea,
      'seguro_desgravamen': model.hasInsurance ? 'Sí' : 'No',
      'canal': 'cliente',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    Map<String, dynamic> result;
    try {
      final row = await client
          .from('solicitudes_credito')
          .insert(data)
          .select()
          .single();
      result = Map<String, dynamic>.from(row as Map);
      debugPrint(
          '[CLIENT_LOAN] request created expediente=$expediente');
    } catch (e) {
      debugPrint('[CLIENT_LOAN] full insert error: $e');
      debugPrint('[CLIENT_LOAN] retrying with minimal fields');
      final minimalData = <String, dynamic>{
        'numero_expediente': expediente,
        'cliente_id': clienteId,
        'monto_solicitado': monto,
        'plazo_meses': model.loanTerm,
        'cuota_estimada': model.estimatedInstallment,
        'cronograma_json': jsonEncode(model.schedule),
        'estado': 'enviado',
        'canal': 'cliente',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final row = await client
          .from('solicitudes_credito')
          .insert(minimalData)
          .select()
          .single();
      result = Map<String, dynamic>.from(row as Map);
      debugPrint(
          '[CLIENT_LOAN] request created (minimal) expediente=$expediente');
    }

    return result;
  }
}
