import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/account_model.dart';
import '../model/credit_model.dart';
import '../model/payment_schedule_model.dart';
import 'auth_repository.dart';

class CreditPaymentResult {
  const CreditPaymentResult({
    required this.numeroOperacion,
    required this.montoPagado,
    required this.numeroCuota,
  });

  final String numeroOperacion;
  final double montoPagado;
  final int numeroCuota;
}

class CreditPaymentRepository {
  CreditPaymentRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  String? get _userId => _auth.currentUser?.id;

  Future<CreditPaymentResult> payNextInstallment({
    required CreditModel credit,
    required PaymentScheduleModel installment,
    required AccountModel originAccount,
  }) async {
    if (!_auth.isConfigured || _userId == null) {
      throw StateError('Supabase no está disponible.');
    }

    final userId = _userId!;
    final client = _client ?? supabase;
    final now = DateTime.now();
    final cuotaMonto = installment.amount;
    final numeroOperacion = 'ALF-CUOTA-${now.millisecondsSinceEpoch}';

    // ── 1. Validate installment is still pending ──
    debugPrint('[CREDIT_PAYMENT] validating installment status');

    final currentRow = await client
        .from('clientes_cronograma_pagos')
        .select('id, estado')
        .eq('id', installment.id!)
        .eq('cliente_id', userId)
        .limit(1)
        .maybeSingle();

    if (currentRow == null) {
      throw StateError('La cuota no existe.');
    }

    final currentEstado =
        (currentRow as Map)['estado']?.toString().trim().toLowerCase() ?? '';
    if (currentEstado.contains('pag')) {
      throw StateError('La cuota ya fue pagada.');
    }

    // ── 2. Validate account balance ──
    debugPrint('[CREDIT_PAYMENT] validating account balance');

    final available = originAccount.availableBalance ?? originAccount.balance;
    if (available < cuotaMonto) {
      throw StateError('Saldo insuficiente para pagar la cuota.');
    }

    // ── 3. Take snapshots for rollback ──
    final oldSaldo = originAccount.balance;
    final oldDisponible = available;
    final oldContable =
        originAccount.accountingBalance ?? originAccount.balance;

    // ── 4. Debit account ──
    debugPrint('[CREDIT_PAYMENT] debit account');
    try {
      await client
          .from('clientes_cuentas')
          .update({
            'saldo': oldSaldo - cuotaMonto,
            'saldo_disponible': oldDisponible - cuotaMonto,
            'saldo_contable': oldContable - cuotaMonto,
          })
          .eq('cliente_id', userId)
          .eq('numero_cuenta', originAccount.accountNumber);
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] debit failed: $e');
      throw StateError('No se pudo debitar la cuenta.');
    }

    // ── 5. Insert movement ──
    debugPrint('[CREDIT_PAYMENT] insert movement');
    String? movementId;
    try {
      final movResult = await client.from('clientes_movimientos').insert({
        'cliente_id': userId,
        'fecha': now.toIso8601String(),
        'monto': cuotaMonto,
        'es_abono': false,
        'descripcion':
            'Pago de cuota ${installment.installmentNumber} del crédito ${credit.productName}',
        'categoria': 'Pago de crédito',
        'referencia': numeroOperacion,
      }).select('id').maybeSingle();
      movementId = (movResult as Map?)?.values.firstOrNull?.toString();
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] movement insert failed: $e');
      await _rollbackDebit(client, userId, originAccount.accountNumber,
          oldSaldo, oldDisponible, oldContable);
      throw StateError('No se pudo registrar el movimiento.');
    }

    // ── 6. Insert operation ──
    debugPrint('[CREDIT_PAYMENT] insert operation');
    String? operationId;
    try {
      final opResult = await client.from('clientes_operaciones').insert({
        'cliente_id': userId,
        'cuenta_origen': originAccount.accountNumber,
        'cuenta_destino': 'Crédito Alfin',
        'monto': cuotaMonto,
        'descripcion': 'Pago de cuota de crédito',
        'numero_operacion': numeroOperacion,
        'fecha': now.toIso8601String(),
        'estado': 'Completada',
        'tipo_operacion': 'PAGO_CUOTA_CREDITO',
      }).select('id').maybeSingle();
      operationId = (opResult as Map?)?.values.firstOrNull?.toString();
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] operation insert failed: $e');
      await _rollbackMovement(client, userId, movementId);
      await _rollbackDebit(client, userId, originAccount.accountNumber,
          oldSaldo, oldDisponible, oldContable);
      throw StateError('No se pudo registrar la operación.');
    }

    // ── 7. Mark installment as paid ──
    debugPrint('[CREDIT_PAYMENT] update installment');
    try {
      await client
          .from('clientes_cronograma_pagos')
          .update({
            'estado': 'pagado',
            'fecha_pago': now.toIso8601String(),
          })
          .eq('id', installment.id!)
          .eq('cliente_id', userId);
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] installment update failed: $e');
      await _rollbackOperation(client, userId, operationId);
      await _rollbackMovement(client, userId, movementId);
      await _rollbackDebit(client, userId, originAccount.accountNumber,
          oldSaldo, oldDisponible, oldContable);
      throw StateError('No se pudo actualizar la cuota.');
    }

    // ── 8. Update credit ──
    debugPrint('[CREDIT_PAYMENT] update credit');
    try {
      final newPending =
          (credit.pendingAmount - cuotaMonto).clamp(0, double.infinity);
      final montoOriginal = credit.montoOriginal ?? credit.pendingAmount;
      final newProgress = montoOriginal > 0
          ? ((montoOriginal - newPending) / montoOriginal).clamp(0.0, 1.0)
          : 0.0;

      final creditUpdate = <String, dynamic>{
        'monto_pendiente': newPending,
        'progreso_pago': newProgress,
      };

      if (newPending <= 0) {
        creditUpdate['estado'] = 'CANCELADO';
        creditUpdate['activo'] = false;
      } else {
        creditUpdate['estado'] = 'ACTIVO';
        creditUpdate['activo'] = true;

        // Update next payment date from the next pending installment
        try {
          final next = await client
              .from('clientes_cronograma_pagos')
              .select('fecha_vencimiento')
              .eq('credito_id', credit.id!)
              .eq('cliente_id', userId)
              .eq('estado', 'pendiente')
              .order('numero_cuota', ascending: true)
              .limit(1)
              .maybeSingle();

          if (next != null) {
            final nextFecha =
                (next as Map)['fecha_vencimiento']?.toString();
            if (nextFecha != null) {
              creditUpdate['proxima_fecha_pago'] = nextFecha;
              creditUpdate['fecha_proximo_pago'] = nextFecha;
            }
          }
        } catch (_) {
          // non-critical, leave date unchanged
        }
      }

      await client
          .from('clientes_creditos')
          .update(creditUpdate)
          .eq('cliente_id', userId)
          .eq('id', credit.id!);
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] credit update failed: $e');
      // rollback installment to pending
      await _rollbackInstallment(
          client, userId, installment.id!);
      await _rollbackOperation(client, userId, operationId);
      await _rollbackMovement(client, userId, movementId);
      await _rollbackDebit(client, userId, originAccount.accountNumber,
          oldSaldo, oldDisponible, oldContable);
      throw StateError('No se pudo actualizar el crédito.');
    }

    debugPrint('[CREDIT_PAYMENT] payment completed numero=$numeroOperacion');

    return CreditPaymentResult(
      numeroOperacion: numeroOperacion,
      montoPagado: cuotaMonto,
      numeroCuota: installment.installmentNumber,
    );
  }

  // ── Rollback helpers ──

  Future<void> _rollbackDebit(
    SupabaseClient client,
    String userId,
    String accountNumber,
    double oldSaldo,
    double oldDisponible,
    double oldContable,
  ) async {
    try {
      await client
          .from('clientes_cuentas')
          .update({
            'saldo': oldSaldo,
            'saldo_disponible': oldDisponible,
            'saldo_contable': oldContable,
          })
          .eq('cliente_id', userId)
          .eq('numero_cuenta', accountNumber);
      debugPrint('[CREDIT_PAYMENT] rollback debit ok');
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] rollback debit failed: $e');
    }
  }

  Future<void> _rollbackMovement(
    SupabaseClient client,
    String userId,
    String? movementId,
  ) async {
    if (movementId == null || movementId.isEmpty) return;
    try {
      await client
          .from('clientes_movimientos')
          .delete()
          .eq('id', movementId)
          .eq('cliente_id', userId);
      debugPrint('[CREDIT_PAYMENT] rollback movement ok');
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] rollback movement failed: $e');
    }
  }

  Future<void> _rollbackOperation(
    SupabaseClient client,
    String userId,
    String? operationId,
  ) async {
    if (operationId == null || operationId.isEmpty) return;
    try {
      await client
          .from('clientes_operaciones')
          .delete()
          .eq('id', operationId)
          .eq('cliente_id', userId);
      debugPrint('[CREDIT_PAYMENT] rollback operation ok');
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] rollback operation failed: $e');
    }
  }

  Future<void> _rollbackInstallment(
    SupabaseClient client,
    String userId,
    String installmentId,
  ) async {
    try {
      await client
          .from('clientes_cronograma_pagos')
          .update({
            'estado': 'pendiente',
            'fecha_pago': null,
          })
          .eq('id', installmentId)
          .eq('cliente_id', userId);
      debugPrint('[CREDIT_PAYMENT] rollback installment ok');
    } catch (e) {
      debugPrint('[CREDIT_PAYMENT] rollback installment failed: $e');
    }
  }
}
