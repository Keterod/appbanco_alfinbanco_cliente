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
}
