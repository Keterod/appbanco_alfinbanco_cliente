import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import 'auth_repository.dart';

class DisbursementRepository {
  DisbursementRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  Future<void> reflectDisbursedRequests() async {
    debugPrint('[DISBURSEMENT] checking disbursed requests');

    if (!_auth.isConfigured) return;
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    final client = _client ?? supabase;

    final perfilRow = await client
        .from('clientes_perfil')
        .select('dni')
        .eq('id', userId)
        .maybeSingle();

    if (perfilRow == null) {
      debugPrint('[DISBURSEMENT] clientes_perfil not found');
      return;
    }
    final perfil = Map<String, dynamic>.from(perfilRow as Map);
    final dni = perfil['dni']?.toString();
    if (dni == null || dni.isEmpty) {
      debugPrint('[DISBURSEMENT] DNI not found');
      return;
    }

    final clienteRow = await client
        .from('clientes')
        .select('id')
        .eq('numero_documento', dni)
        .maybeSingle();

    if (clienteRow == null) {
      debugPrint('[DISBURSEMENT] clientes not found');
      return;
    }
    final cliente = Map<String, dynamic>.from(clienteRow as Map);
    final clienteId = cliente['id']?.toString();
    if (clienteId == null) {
      debugPrint('[DISBURSEMENT] cliente_id not found');
      return;
    }
    debugPrint('[DISBURSEMENT] cliente_id=$clienteId userId=$userId');

    // Query by cliente_id OR created_by_auth_id
    List<Map<String, dynamic>> requests;
    try {
      final rows = await client
          .from('solicitudes_credito')
          .select()
          .or(
            'cliente_id.eq.$clienteId,'
            'created_by_auth_id.eq.$userId',
          )
          .eq('estado', 'desembolsado');
      requests = List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      debugPrint('[DISBURSEMENT] OR query failed, using fallback');
      final rows = await client
          .from('solicitudes_credito')
          .select()
          .eq('cliente_id', clienteId)
          .eq('estado', 'desembolsado');
      requests = List<Map<String, dynamic>>.from(rows as List);
    }

    debugPrint('[DISBURSEMENT] found=${requests.length}');

    for (final req in requests) {
      await _reflectSingle(client, userId, req);
    }
  }

  Future<void> _reflectSingle(
    SupabaseClient client,
    String userId,
    Map<String, dynamic> req,
  ) async {
    final expediente = req['numero_expediente']?.toString() ?? '';
    final solicitudId = req['id']?.toString() ?? '';

    debugPrint('[DISBURSEMENT] processing expediente=$expediente');

    // Skip rechazado (should not happen since we query desembolsado)
    final estado = (req['estado']?.toString() ?? '').toLowerCase().trim();
    if (estado == 'rechazado') {
      debugPrint('[DISBURSEMENT] skipping rejected request');
      return;
    }

    // Check duplicates
    final existingBySolicitudId = solicitudId.isNotEmpty
        ? await client
            .from('clientes_creditos')
            .select('id')
            .eq('solicitud_id', solicitudId)
            .limit(1)
            .maybeSingle()
        : null;

    if (existingBySolicitudId != null) {
      debugPrint('[DISBURSEMENT] already reflected (solicitud_id)');
      return;
    }

    if (expediente.isNotEmpty) {
      final existingByExpediente = await client
          .from('clientes_creditos')
          .select('id')
          .eq('numero_expediente', expediente)
          .limit(1)
          .maybeSingle();

      if (existingByExpediente != null) {
        debugPrint('[DISBURSEMENT] already reflected (expediente)');
        return;
      }
    }

    debugPrint('[DISBURSEMENT] reflecting expediente=$expediente');

    // Use monto_aprobado for condicionado, fallback to monto_solicitado
    final montoOriginal =
        (req['monto_solicitado'] as num?)?.toDouble() ?? 0;
    final montoAprobado = (req['monto_aprobado'] as num?)?.toDouble() ??
        montoOriginal;
    final plazoSolicitado = (req['plazo_meses'] as num?)?.toInt() ?? 12;
    final fechaDesembolsoStr = req['fecha_desembolso']?.toString();
    final fechaDesembolso = fechaDesembolsoStr != null
        ? DateTime.tryParse(fechaDesembolsoStr) ?? DateTime.now()
        : DateTime.now();

    final now = DateTime.now();
    final numeroCredito = 'CRE-${now.millisecondsSinceEpoch}';

    // Calculate cuota for monto_aprobado (recalculates for condicionado)
    final hasInsurance = req['seguro_desgravamen']?.toString() == 'Sí';
    final tea = hasInsurance ? 40.92 : 43.92;
    final tem = pow(1 + tea / 100, 1 / 12) - 1;
    final denom = 1 - pow(1 + tem, -plazoSolicitado);
    final cuotaMensual =
        denom != 0 ? montoAprobado * tem / denom : 0;

    final creditData = <String, dynamic>{
      'cliente_id': userId,
      'nombre_producto': 'Crédito Empresarial — Microempresa',
      'numero_credito': numeroCredito,
      'monto_original': montoAprobado,
      'monto_pendiente': montoAprobado,
      'cuota_mensual': cuotaMensual,
      'tea': tea,
      'progreso_pago': 0,
      'activo': true,
      'estado': 'ACTIVO',
      'fecha_desembolso': fechaDesembolso.toIso8601String(),
      'solicitud_id': solicitudId,
      'numero_expediente': expediente,
    };

    Map<String, dynamic>? creditRow;
    try {
      final inserted = await client
          .from('clientes_creditos')
          .insert(creditData)
          .select()
          .single();
      creditRow = Map<String, dynamic>.from(inserted as Map);
      debugPrint('[DISBURSEMENT] credit inserted');
    } catch (e) {
      debugPrint('[DISBURSEMENT] full credit insert error: $e');
      try {
        final minimalCredit = <String, dynamic>{
          'cliente_id': userId,
          'nombre_producto': 'Crédito Empresarial — Microempresa',
          'numero_credito': numeroCredito,
          'monto_original': montoAprobado,
          'monto_pendiente': montoAprobado,
          'cuota_mensual': cuotaMensual,
          'tea': tea,
          'progreso_pago': 0,
          'activo': true,
        };
        final inserted = await client
            .from('clientes_creditos')
            .insert(minimalCredit)
            .select()
            .single();
        creditRow = Map<String, dynamic>.from(inserted as Map);
        debugPrint('[DISBURSEMENT] credit inserted (minimal)');
      } catch (e2) {
        debugPrint('[DISBURSEMENT] minimal credit insert also failed: $e2');
      }
    }

    if (creditRow == null) {
      debugPrint('[DISBURSEMENT] failed to create credit row');
      return;
    }

    final creditoId = creditRow['id']?.toString() ?? '';

    // Insert schedule rows
    final cronogramaRaw = req['cronograma_json'];
    List<Map<String, dynamic>> scheduleRows = [];

    if (cronogramaRaw != null) {
      List<dynamic> cronogramaList;
      if (cronogramaRaw is List) {
        cronogramaList = cronogramaRaw;
      } else if (cronogramaRaw is String && cronogramaRaw.isNotEmpty) {
        try {
          cronogramaList = List<dynamic>.from(
              const JsonDecoder().convert(cronogramaRaw) as List);
        } catch (_) {
          cronogramaList = [];
        }
      } else {
        cronogramaList = [];
      }

      // Recalculate schedule if monto_aprobado differs from original
      final needsRecalc = (montoAprobado - montoOriginal).abs() > 0.01;
      if (needsRecalc) {
        scheduleRows = _generateSchedule(
          userId: userId,
          creditoId: creditoId,
          monto: montoAprobado,
          plazo: plazoSolicitado,
          tea: tea,
        );
      } else {
        for (final cuotaJson in cronogramaList) {
          final c = cuotaJson as Map<String, dynamic>;
          scheduleRows.add({
            'cliente_id': userId,
            'credito_id': creditoId,
            'numero_cuota':
                (c['numero_cuota'] ?? c['numeroCuota'] ?? 0) as int,
            'fecha_vencimiento':
                c['fecha_pago']?.toString() ?? c['fechaPago']?.toString() ?? '',
            'monto': (c['cuota'] as num?)?.toDouble() ?? 0,
            'estado': 'Pendiente',
          });
        }
      }
    }

    if (scheduleRows.isEmpty) {
      scheduleRows = _generateSchedule(
        userId: userId,
        creditoId: creditoId,
        monto: montoAprobado,
        plazo: plazoSolicitado,
        tea: tea,
      );
    }

    for (final row in scheduleRows) {
      await client.from('clientes_cronograma_pagos').insert(row);
    }
    debugPrint('[DISBURSEMENT] schedule inserted rows=${scheduleRows.length}');

    // Get main account and credit it
    final accountRows = await client
        .from('clientes_cuentas')
        .select()
        .eq('cliente_id', userId)
        .eq('es_principal', true)
        .limit(1);

    final accountList = List<Map<String, dynamic>>.from(accountRows as List);
    if (accountList.isEmpty) {
      debugPrint('[DISBURSEMENT] no main account found');
      return;
    }
    final account = accountList.first;
    final accountNumber = account['numero_cuenta']?.toString() ?? '';
    final currentSaldo =
        (account['saldo'] as num?)?.toDouble() ?? 0;
    final currentDisponible =
        (account['saldo_disponible'] as num?)?.toDouble() ?? currentSaldo;
    final currentContable =
        (account['saldo_contable'] as num?)?.toDouble() ?? currentSaldo;

    await client
        .from('clientes_cuentas')
        .update({
          'saldo': currentSaldo + montoAprobado,
          'saldo_disponible': currentDisponible + montoAprobado,
          'saldo_contable': currentContable + montoAprobado,
        })
        .eq('cliente_id', userId)
        .eq('es_principal', true);
    debugPrint('[DISBURSEMENT] account credited amount=$montoAprobado');

    // Insert movement
    await client.from('clientes_movimientos').insert({
      'cliente_id': userId,
      'fecha': now.toIso8601String(),
      'monto': montoAprobado,
      'es_abono': true,
      'descripcion': 'Desembolso de crédito $expediente',
      'categoria': 'Crédito',
      'referencia': expediente.isNotEmpty ? expediente : numeroCredito,
    });
    debugPrint('[DISBURSEMENT] movement inserted');

    // Insert operation
    final operationNumber =
        'ALF-DES-${now.millisecondsSinceEpoch}';
    await client.from('clientes_operaciones').insert({
      'cliente_id': userId,
      'cuenta_origen': 'Banco Alfin',
      'cuenta_destino': accountNumber,
      'monto': montoAprobado,
      'descripcion': 'Desembolso de crédito empresarial',
      'numero_operacion': operationNumber,
      'fecha': now.toIso8601String(),
      'estado': 'Completada',
      'tipo_operacion': 'DESEMBOLSO_CREDITO',
    });
    debugPrint('[DISBURSEMENT] operation inserted');
  }

  List<Map<String, dynamic>> _generateSchedule({
    required String userId,
    required String creditoId,
    required double monto,
    required int plazo,
    required double tea,
  }) {
    final tem = pow(1 + tea / 100, 1 / 12) - 1;
    final denom = 1 - pow(1 + tem, -plazo);
    final cuota = denom != 0 ? monto * tem / denom : 0;
    final hoy = DateTime.now();
    final rows = <Map<String, dynamic>>[];
    double saldo = monto;

    for (var i = 1; i <= plazo; i++) {
      final interes = saldo * tem;
      final capital = cuota - interes;
      saldo -= capital;
      if (saldo < 0) saldo = 0;

      final fecha = DateTime(hoy.year, hoy.month + i, hoy.day);
      rows.add({
        'cliente_id': userId,
        'credito_id': creditoId,
        'numero_cuota': i,
        'fecha_vencimiento': fecha.toIso8601String(),
        'monto': cuota,
        'estado': 'Pendiente',
      });
    }

    return rows;
  }
}
