import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/auth_repository.dart';

/// ViewModel de autenticación con Supabase y respaldo en modo demostración.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  bool isLoading = false;
  bool isSuccess = false;
  bool usedDemoMode = false;
  String? errorMessage;

  final String demoEmail = 'demo@alfinbanco.pe';
  final String demoPassword = '123456';

  Future<void> login(String email, String password) async {
    errorMessage = null;
    isSuccess = false;
    usedDemoMode = false;
    isLoading = true;
    notifyListeners();

    if (_authRepository.isConfigured) {
      try {
        final response = await _authRepository.signInWithEmail(
          email,
          password,
        );
        if (response.session != null) {
          isLoading = false;
          isSuccess = true;
          notifyListeners();
          return;
        }
        errorMessage = 'Correo o contraseña incorrectos.';
      } on AuthException catch (e) {
        errorMessage = _mapAuthError(e);
      } catch (e) {
        if (_isConnectionError(e)) {
          final demoOk = await _tryDemoLogin(email, password);
          if (demoOk) return;
          errorMessage = 'Verifica tu conexión.';
        } else {
          final message = e.toString().toLowerCase();
          if (message.contains('invalid') ||
              message.contains('credentials') ||
              message.contains('password')) {
            errorMessage = 'Correo o contraseña incorrectos.';
          } else if (message.contains('not found') ||
              message.contains('user')) {
            errorMessage = 'Usuario no registrado.';
          } else {
            final demoOk = await _tryDemoLogin(email, password);
            if (demoOk) return;
            errorMessage = 'No se pudo iniciar sesión. Intenta de nuevo.';
          }
        }
      }
    } else {
      final demoOk = await _tryDemoLogin(email, password);
      if (demoOk) return;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> _tryDemoLogin(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    usedDemoMode = true;
    isLoading = false;
    isSuccess = true;
    errorMessage = null;
    notifyListeners();
    return true;
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') ||
        msg.contains('credentials') ||
        msg.contains('password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (msg.contains('not found') || msg.contains('user')) {
      return 'Usuario no registrado.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Verifica tu conexión.';
    }
    return e.message;
  }

  bool _isConnectionError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('timeout') ||
        text.contains('failed host lookup');
  }
}
