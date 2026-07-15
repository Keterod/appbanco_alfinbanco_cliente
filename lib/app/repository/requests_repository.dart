import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_bootstrap.dart';
import '../core/supabase/supabase_client.dart';
import '../core/supabase/supabase_config.dart';
import '../model/request_model.dart';

class RequestsRepository {
  bool get _isConfigured =>
      SupabaseConfig.isConfigured && SupabaseBootstrap.initialized;

  SupabaseClient? get _client {
    if (!_isConfigured) return null;
    try {
      return supabase;
    } catch (_) {
      return null;
    }
  }

  Future<List<RequestModel>> getRequests() async {
    final client = _client;
    if (client == null) {
      debugPrint('[REQUESTS] Supabase no disponible');
      return [];
    }

    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      debugPrint('[REQUESTS] No hay sesión activa');
      return [];
    }
    debugPrint('[REQUESTS] currentUser=${currentUser.id}');

    Map<String, dynamic>? perfil;
    try {
      final row = await client
          .from('clientes_perfil')
          .select('dni')
          .eq('id', currentUser.id)
          .maybeSingle();
      if (row != null) {
        perfil = Map<String, dynamic>.from(row as Map);
      }
    } catch (e) {
      debugPrint('[REQUESTS] error al leer clientes_perfil: $e');
      return [];
    }

    final dni = perfil?['dni']?.toString();
    if (dni == null || dni.isEmpty) {
      debugPrint('[REQUESTS] DNI no encontrado en perfil');
      return [];
    }
    debugPrint('[REQUESTS] dni perfil=$dni');

    Map<String, dynamic>? cliente;
    try {
      final row = await client
          .from('clientes')
          .select('id')
          .eq('numero_documento', dni)
          .maybeSingle();
      if (row != null) {
        cliente = Map<String, dynamic>.from(row as Map);
      }
    } catch (e) {
      debugPrint('[REQUESTS] error al leer clientes: $e');
      return [];
    }

    final clienteId = cliente?['id']?.toString();
    if (clienteId == null || clienteId.isEmpty) {
      debugPrint('[REQUESTS] cliente corporativo no encontrado para DNI=$dni');
      return [];
    }
    debugPrint('[REQUESTS] cliente corporativo id=$clienteId');

    try {
      // Query by cliente_id OR created_by_auth_id (for demo-created requests)
      List<Map<String, dynamic>> list;

      try {
        final rows = await client
            .from('solicitudes_credito')
            .select()
            .or(
              'cliente_id.eq.$clienteId,'
              'created_by_auth_id.eq.${currentUser.id}',
            )
            .order('created_at', ascending: false);

        list = List<Map<String, dynamic>>.from(rows as List);
      } catch (_) {
        // Fallback if created_by_auth_id column doesn't exist
        debugPrint('[REQUESTS] OR query failed, using fallback');
        final rows = await client
            .from('solicitudes_credito')
            .select()
            .eq('cliente_id', clienteId)
            .order('created_at', ascending: false);

        list = List<Map<String, dynamic>>.from(rows as List);
      }

      debugPrint('[REQUESTS] solicitudes encontradas=${list.length}');

      return list.map((r) => RequestModel.fromSupabase(r)).toList();
    } catch (e) {
      debugPrint('[REQUESTS] error al leer solicitudes_credito: $e');
      return [];
    }
  }
}
