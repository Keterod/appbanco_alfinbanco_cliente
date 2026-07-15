import 'package:flutter/foundation.dart';
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

  Future<List<CreditModel>> getCredits() async {
    if (!_auth.isConfigured || _userId == null) return [];

    final userId = _userId!;
    final client = _client ?? supabase;

    debugPrint('DEBUG CLIENTES CREDITOS: userId=$userId');

    final rows = await client
        .from('clientes_creditos')
        .select()
        .eq('cliente_id', userId)
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(rows as List);
    debugPrint('DEBUG CLIENTES CREDITOS: count=${list.length}');
    debugPrint(
        'DEBUG CLIENTES CREDITOS: first=${list.isNotEmpty ? list.first : null}');

    return list.map((r) => CreditModel.fromSupabase(r)).toList();
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
}
