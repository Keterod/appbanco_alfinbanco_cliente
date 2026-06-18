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

    // 1. Bridge: auth.uid() → clientes_perfil.dni → clientes.id
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

    // 2. Query disbursed requests
    final rows = await client
        .from('solicitudes_credito')
        .select()
        .eq('cliente_id', clienteId)
        .eq('estado', 'desembolsado');

    final requests = List<Map<String, dynamic>>.from(rows as List);
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

    // 3. Check for duplicates
    final existingBySolicitudId = solicitudId.isNotEmpty
        ? await client
            .from('clientes_creditos')
            .select('id')
            .eq('solicitud_id', solicitudId)
            .limit(1)
            .maybeSingle()
        : null;

    if (existingBySolicitudId != null) {
      debugPrint('[DISBURSEMENT] already reflected (solicitud_id) expediente=$expediente');
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
        debugPrint('[DISBURSEMENT] already reflected (expediente) expediente=$expediente');
        return;
      }
    }

    debugPrint('[DISBURSEMENT] reflecting expediente=$expediente');

    final montoAprobado = (req['monto_aprobado'] as num?)?.toDouble() ??
        (req['monto_solicitado'] as num?)?.toDouble() ?? 0;
    final plazoSolicitado = (req['plazo_meses'] as num?)?.toInt() ?? 12;
    final cuotaEstimada =
        (req['cuota_estimada'] as num?)?.toDouble() ?? 0;
    final teaReferencial =
        (req['tea_referencial'] as num?)?.toDouble() ?? 43.92;
    final fechaDesembolsoStr = req['fecha_desembolso']?.toString();
    final fechaDesembolso = fechaDesembolsoStr != null
        ? DateTime.tryParse(fechaDesembolsoStr) ?? DateTime.now()
        : DateTime.now();

    final now = DateTime.now();
    final numeroCredito = 'CRE-${now.millisecondsSinceEpoch}';

    // 4. Insert into clientes_creditos
    final creditData = <String, dynamic>{
      'cliente_id': userId,
      'nombre_producto': 'Crédito Empresarial — Microempresa',
      'numero_credito': numeroCredito,
      'monto_original': montoAprobado,
      'monto_pendiente': montoAprobado,
      'cuota_mensual': cuotaEstimada,
      'tea': teaReferencial,
      'progreso': 0,
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
          'cuota_mensual': cuotaEstimada,
          'tea': teaReferencial,
          'progreso': 0,
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

    // 5. Insert schedule rows into clientes_cronograma_pagos
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

      for (final cuota in cronogramaList) {
        final c = cuota as Map<String, dynamic>;
        scheduleRows.add({
          'cliente_id': userId,
          'credito_id': creditoId,
          'numero_cuota':
              (c['numero_cuota'] ?? c['numeroCuota'] ?? 0) as int,
          'fecha_vencimiento':
              c['fecha_pago']?.toString() ?? c['fechaPago']?.toString() ?? '',
          'monto': (c['cuota'] as num?)?.toDouble() ?? 0,
          'capital': (c['capital'] as num?)?.toDouble() ?? 0,
          'interes': (c['interes'] as num?)?.toDouble() ?? 0,
          'saldo': (c['saldo'] as num?)?.toDouble() ?? 0,
          'estado': 'Pendiente',
        });
      }
    }

    if (scheduleRows.isEmpty) {
      scheduleRows = _generateSchedule(
        userId: userId,
        creditoId: creditoId,
        monto: montoAprobado,
        plazo: plazoSolicitado,
        tea: teaReferencial,
      );
    }

    for (final row in scheduleRows) {
      await client.from('clientes_cronograma_pagos').insert(row);
    }
    debugPrint('[DISBURSEMENT] schedule inserted rows=${scheduleRows.length}');

    // 6. Get main account and credit it
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

    // 7. Insert movement
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

    // 8. Insert operation
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
        'capital': capital,
        'interes': interes,
        'saldo': saldo,
        'estado': 'Pendiente',
      });
    }

    return rows;
  }
}
