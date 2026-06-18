import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_bootstrap.dart';
import '../core/supabase/supabase_client.dart';
import '../core/supabase/supabase_config.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient? get _safeClient {
    if (!isConfigured) return null;
    try {
      return _client ?? supabase;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured =>
      SupabaseConfig.isConfigured && SupabaseBootstrap.initialized;

  User? get currentUser => _safeClient?.auth.currentUser;

  static void _debugPrintError(Object error, String context) {
    debugPrint('DEBUG SIGNUP ERROR [$context]: tipo=${error.runtimeType}');
    debugPrint('DEBUG SIGNUP ERROR [$context]: mensaje=$error');

    if (error is AuthException) {
      debugPrint('DEBUG SIGNUP ERROR [$context]: statusCode=${error.statusCode}');
      debugPrint('DEBUG SIGNUP ERROR [$context]: code=${error.code}');
    }

    if (error is PostgrestException) {
      debugPrint('DEBUG SIGNUP ERROR [$context]: code=${error.code}');
      debugPrint('DEBUG SIGNUP ERROR [$context]: message=${error.message}');
      debugPrint('DEBUG SIGNUP ERROR [$context]: details=${error.details}');
      debugPrint('DEBUG SIGNUP ERROR [$context]: hint=${error.hint}');
    }

    if (error is Exception) {
      final ex = error;
      debugPrint('DEBUG SIGNUP ERROR [$context]: toString=${ex.toString()}');
    }
  }

  Future<AuthResponse> signUpClient({
    required String email,
    required String password,
    required String dni,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String tipoCliente,
  }) async {
    final client = _safeClient;
    if (client == null) {
      throw StateError('Supabase no está disponible.');
    }

    AuthResponse response;
    User user;

    try {
      debugPrint('DEBUG SIGNUP: iniciando signUp');
      response = await client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final signedUpUser = response.user;
      debugPrint('DEBUG SIGNUP: signUp completado');
      debugPrint('DEBUG SIGNUP: user id=${signedUpUser?.id}');
      debugPrint('DEBUG SIGNUP: email=${signedUpUser?.email}');
      debugPrint(
        'DEBUG SIGNUP: session=${response.session != null ? "sí" : "no"}',
      );

      if (signedUpUser == null) {
        throw const AuthException('No se pudo crear el usuario.');
      }
      user = signedUpUser;
    } catch (e, stackTrace) {
      _debugPrintError(e, 'signUp');
      debugPrint('DEBUG SIGNUP: stackTrace=$stackTrace');
      rethrow;
    }

    try {
      debugPrint('DEBUG SIGNUP: insertando perfil');
      await client.from('clientes_perfil').insert({
        'id': user.id,
        'dni': dni,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefono': telefono,
        'email': email.trim(),
        'direccion': direccion,
        'tipo_cliente': tipoCliente,
      });
      debugPrint('DEBUG SIGNUP: perfil insertado correctamente');
    } catch (e, stackTrace) {
      _debugPrintError(e, 'insert clientes_perfil');
      debugPrint('DEBUG SIGNUP: stackTrace=$stackTrace');
      rethrow;
    }

    try {
      debugPrint('DEBUG SIGNUP: llamando RPC crear_data_demo_cliente');
      await client.rpc('crear_data_demo_cliente', params: {
        'user_id': user.id,
      });
      debugPrint('DEBUG SIGNUP: RPC completada correctamente');
    } catch (e, stackTrace) {
      _debugPrintError(e, 'RPC crear_data_demo_cliente');
      debugPrint('DEBUG SIGNUP: stackTrace=$stackTrace');
      rethrow;
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final client = _safeClient;
    if (client == null) {
      throw StateError('Supabase no está disponible.');
    }

    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    final client = _safeClient;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<void> createDemoDataForCurrentUser() async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await createDemoDataForUser(userId);
  }

  Future<void> createDemoDataForUser(String userId) async {
    final client = _safeClient;
    if (client == null) return;

    try {
      debugPrint('DEBUG SIGNUP: llamando RPC crear_data_demo_cliente');
      await client.rpc('crear_data_demo_cliente', params: {
        'user_id': userId,
      });
    } catch (e, stackTrace) {
      _debugPrintError(e, 'RPC crear_data_demo_cliente');
      debugPrint('DEBUG SIGNUP: stackTrace=$stackTrace');
      rethrow;
    }
  }
}
