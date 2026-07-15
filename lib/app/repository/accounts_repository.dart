import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/account_model.dart';
import '../model/movement_model.dart';
import 'auth_repository.dart';

class AccountsRepository {
  AccountsRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  String? get _userId => _auth.currentUser?.id;

  Future<AccountModel?> getMainAccount() async {
    if (!_auth.isConfigured || _userId == null) return null;

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_cuentas')
        .select()
        .eq('cliente_id', _userId!)
        .order('es_principal', ascending: false);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return null;

    final main = list.firstWhere(
      (r) => r['es_principal'] == true,
      orElse: () => list.first,
    );
    return AccountModel.fromSupabase(main);
  }

  Future<List<MovementModel>> getMovements() async {
    if (!_auth.isConfigured || _userId == null) return [];

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_movimientos')
        .select()
        .eq('cliente_id', _userId!)
        .order('fecha', ascending: false);

    final list = List<Map<String, dynamic>>.from(rows as List);
    return list
        .map((r) => MovementModel.fromSupabase(r))
        .toList();
  }

  Future<double?> getCurrentBalance() async {
    if (!_auth.isConfigured || _userId == null) return null;

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_cuentas')
        .select('saldo')
        .eq('cliente_id', _userId!)
        .eq('es_principal', true)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return null;
    return (list.first['saldo'] as num?)?.toDouble();
  }

  Future<void> insertMovement({
    required double amount,
    required String description,
    required String category,
    required String reference,
    required bool isDebit,
  }) async {
    if (!_auth.isConfigured || _userId == null) {
      throw StateError('Supabase no está disponible.');
    }

    final client = _client ?? supabase;
    await client.from('clientes_movimientos').insert({
      'cliente_id': _userId!,
      'fecha': DateTime.now().toIso8601String(),
      'monto': amount,
      'es_abono': !isDebit,
      'descripcion': description,
      'categoria': category,
      'referencia': reference,
    });
  }

  Future<List<AccountModel>> getAccounts() async {
    if (!_auth.isConfigured || _userId == null) return [];

    final userId = _userId!;
    final client = _client ?? supabase;

    debugPrint('DEBUG CLIENTES CUENTAS: userId=$userId');

    var rows = await client
        .from('clientes_cuentas')
        .select()
        .eq('cliente_id', userId)
        .order('es_principal', ascending: false)
        .order('numero_cuenta', ascending: true);

    var list = List<Map<String, dynamic>>.from(rows as List);

    debugPrint('DEBUG CLIENTES CUENTAS: count=${list.length}');
    debugPrint(
        'DEBUG CLIENTES CUENTAS: first=${list.isNotEmpty ? list.first : null}');

    if (list.isEmpty) {
      debugPrint('[ACCOUNTS] no accounts found, creating default account');
      final now = DateTime.now();
      final numeroCuenta =
          '0011-${now.millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
      final cci =
          '002-011${now.millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}-56';

      await client.from('clientes_cuentas').insert({
        'cliente_id': userId,
        'numero_cuenta': numeroCuenta,
        'cci': cci,
        'tipo_cuenta': 'Cuenta de Ahorros',
        'saldo': 0,
        'saldo_disponible': 0,
        'saldo_contable': 0,
        'moneda': 'PEN',
        'activa': true,
        'es_principal': true,
        'created_at': now.toIso8601String(),
      });

      rows = await client
          .from('clientes_cuentas')
          .select()
          .eq('cliente_id', userId)
          .order('es_principal', ascending: false)
          .order('numero_cuenta', ascending: true);

      list = List<Map<String, dynamic>>.from(rows as List);
      debugPrint('[ACCOUNTS] created default account, count=${list.length}');
    }

    return list
        .map((r) => AccountModel.fromSupabase(r))
        .toList();
  }

  Future<void> updateBalance(double newBalance) async {
    if (!_auth.isConfigured || _userId == null) {
      throw StateError('Supabase no está disponible.');
    }

    final client = _client ?? supabase;
    await client
        .from('clientes_cuentas')
        .update({
          'saldo': newBalance,
          'saldo_disponible': newBalance,
          'saldo_contable': newBalance,
        })
        .eq('cliente_id', _userId!)
        .eq('es_principal', true);
  }

  Future<void> debitAccount({
    required String accountNumber,
    required double amount,
  }) async {
    if (!_auth.isConfigured || _userId == null) {
      throw StateError('Supabase no está disponible.');
    }

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_cuentas')
        .select('saldo, saldo_disponible, saldo_contable')
        .eq('cliente_id', _userId!)
        .eq('numero_cuenta', accountNumber)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) throw StateError('Cuenta no encontrada.');

    final current = list.first;
    final saldo = (current['saldo'] as num?)?.toDouble() ?? 0;
    final disponible = (current['saldo_disponible'] as num?)?.toDouble() ?? saldo;
    final contable = (current['saldo_contable'] as num?)?.toDouble() ?? saldo;

    await client
        .from('clientes_cuentas')
        .update({
          'saldo': saldo - amount,
          'saldo_disponible': disponible - amount,
          'saldo_contable': contable - amount,
        })
        .eq('cliente_id', _userId!)
        .eq('numero_cuenta', accountNumber);
  }

  Future<void> creditAccount({
    required String accountNumber,
    required double amount,
  }) async {
    if (!_auth.isConfigured || _userId == null) {
      throw StateError('Supabase no está disponible.');
    }

    final client = _client ?? supabase;
    final rows = await client
        .from('clientes_cuentas')
        .select('saldo, saldo_disponible, saldo_contable')
        .eq('cliente_id', _userId!)
        .eq('numero_cuenta', accountNumber)
        .limit(1);

    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) throw StateError('Cuenta no encontrada.');

    final current = list.first;
    final saldo = (current['saldo'] as num?)?.toDouble() ?? 0;
    final disponible = (current['saldo_disponible'] as num?)?.toDouble() ?? saldo;
    final contable = (current['saldo_contable'] as num?)?.toDouble() ?? saldo;

    await client
        .from('clientes_cuentas')
        .update({
          'saldo': saldo + amount,
          'saldo_disponible': disponible + amount,
          'saldo_contable': contable + amount,
        })
        .eq('cliente_id', _userId!)
        .eq('numero_cuenta', accountNumber);
  }
}
