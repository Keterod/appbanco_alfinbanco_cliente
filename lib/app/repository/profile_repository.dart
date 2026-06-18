import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_client.dart';
import '../model/user_profile_model.dart';
import 'auth_repository.dart';

class ProfileRepository {
  ProfileRepository({
    AuthRepository? authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository ?? AuthRepository(),
        _client = client;

  final AuthRepository _auth;
  final SupabaseClient? _client;

  Future<UserProfileModel?> getCurrentProfile() async {
    if (!_auth.isConfigured) return null;

    final userId = _auth.currentUser?.id;
    if (userId == null) return null;

    final client = _client ?? supabase;
    final row = await client
        .from('clientes_perfil')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return UserProfileModel.fromSupabase(
      Map<String, dynamic>.from(row as Map),
    );
  }
}
