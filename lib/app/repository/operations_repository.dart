import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/transfer_model.dart';
import 'auth_repository.dart';

class OperationsRepository {
  OperationsRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  Future<TransferModel> createOperation({
    required String originAccount,
    required String destinationAccount,
    required double amount,
    required String description,
    required String tipoOperacion,
    String status = 'Completada',
  }) async {
    if (!_auth.isConfigured) {
      throw StateError('Supabase no está disponible.');
    }

    final userId = _auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay sesión activa.');
    }

    final now = DateTime.now();
    final operationNumber =
        'ALF-OP-${now.millisecondsSinceEpoch}';

    final client = _client ?? supabase;
    final row = await client.from('clientes_operaciones').insert({
      'cliente_id': userId,
      'cuenta_origen': originAccount,
      'cuenta_destino': destinationAccount,
      'monto': amount,
      'descripcion': description,
      'numero_operacion': operationNumber,
      'fecha': now.toIso8601String(),
      'estado': status,
      'tipo_operacion': tipoOperacion,
    }).select().single();

    return TransferModel.fromSupabase(
      Map<String, dynamic>.from(row as Map),
      fallbackOrigin: originAccount,
      fallbackDestination: destinationAccount,
    );
  }
}
