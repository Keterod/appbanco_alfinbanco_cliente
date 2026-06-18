import 'dart:async';

import 'package:flutter/foundation.dart';

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
    profile = DemoClientData.profile;
    unawaited(_loadFromSupabase());
  }

  final AuthRepository _auth;
  final ProfileRepository _profileRepository;

  late UserProfileModel profile;
  bool isLoading = false;
  bool usingSupabaseData = false;

  Future<void> _loadFromSupabase() async {
    if (!_auth.isConfigured || _auth.currentUser == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final remote = await _profileRepository.getCurrentProfile();
      if (remote != null) {
        profile = remote;
        usingSupabaseData = true;
      }
    } catch (e) {
      debugPrint('[ProfileViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[ProfileViewModel] signOut: $e');
    }
  }
}
