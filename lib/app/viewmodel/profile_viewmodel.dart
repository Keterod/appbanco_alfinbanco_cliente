import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/session/session_timeout_manager.dart';
import '../data/demo_client_data.dart';
import '../model/user_profile_model.dart';
import '../repository/auth_repository.dart';
import '../repository/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _profileRepository = profileRepository ?? ProfileRepository() {
    _startLoading();
  }

  final AuthRepository _auth;
  final ProfileRepository _profileRepository;

  UserProfileModel? profile;
  bool isLoading = true;
  bool usingSupabaseData = false;
  String? loadError;

  void _startLoading() {
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    unawaited(_loadFromSupabase());
  }

  Future<void> _loadFromSupabase() async {
    debugPrint('[PROFILE] loading real profile');

    if (!_auth.isConfigured || _auth.currentUser == null) {
      debugPrint('[PROFILE] fallback demo reason=no_session');
      profile = DemoClientData.profile;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final remote = await _profileRepository.getCurrentProfile();

      if (remote != null) {
        profile = remote;
        usingSupabaseData = true;
        debugPrint('[PROFILE] loaded real profile');
      } else {
        debugPrint('[PROFILE] empty profile');
      }

      loadError = null;
    } catch (e) {
      debugPrint('[PROFILE] fallback demo reason=supabase_error');
      profile = DemoClientData.profile;
      loadError = 'No se pudo cargar tu perfil.';
      debugPrint('[ProfileViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    profile = null;
    isLoading = true;
    usingSupabaseData = false;
    loadError = null;
    notifyListeners();
    await _loadFromSupabase();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await SessionTimeoutManager.clearActivity();
      debugPrint('[PROFILE] logout completed');
    } catch (e) {
      debugPrint('[ProfileViewModel] signOut: $e');
    }
  }
}
