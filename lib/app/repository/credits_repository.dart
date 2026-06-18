import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/credit_model.dart';
import '../model/payment_schedule_model.dart';
import 'auth_repository.dart';

class CreditsRepository {
  CreditsRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  String? get _userId => _auth.currentUser?.id;

  Future<CreditModel?> getActiveCredit() async {
    if (!_auth.isConfigured || _userId == null) return null;

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_creditos')
        .select()
        .eq('cliente_id', _userId!)
        .eq('activo', true)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) {
      final fallback = await client
          .from('clientes_creditos')
          .select()
          .eq('cliente_id', _userId!)
          .limit(1);
      final fbList = List<Map<String, dynamic>>.from(fallback as List);
      if (fbList.isEmpty) return null;
      return CreditModel.fromSupabase(fbList.first);
    }

    return CreditModel.fromSupabase(list.first);
  }

  Future<List<PaymentScheduleModel>> getPaymentSchedule({
    String? creditoId,
  }) async {
    if (!_auth.isConfigured || _userId == null) return [];

    final client = _client ?? supabase;
    var query = client
        .from('clientes_cronograma_pagos')
        .select()
        .eq('cliente_id', _userId!);

    if (creditoId != null) {
      query = query.eq('credito_id', creditoId);
    }

    final rows = await query.order('numero_cuota', ascending: true);
    final list = List<Map<String, dynamic>>.from(rows as List);
    return list
        .map((r) => PaymentScheduleModel.fromSupabase(r))
        .toList();
  }

  Future<Map<String, dynamic>?> getActiveCreditRow() async {
    if (!_auth.isConfigured || _userId == null) return null;

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_creditos')
        .select()
        .eq('cliente_id', _userId!)
        .eq('activo', true)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return null;
    return list.first;
  }
}
