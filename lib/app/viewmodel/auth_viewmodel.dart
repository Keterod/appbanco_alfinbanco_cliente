import 'package:flutter/foundation.dart';

/// ViewModel de autenticación (S9: sin validación real; credenciales demo solo referencia).
class AuthViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isSuccess = false;
  String? errorMessage;

  /// Referencia académica — no se usa para bloquear el ingreso en S9.
  final String demoDni = '74859612';
  final String demoPassword = '123456';

  Future<void> login(String dni, String password) async {
    errorMessage = null;
    isSuccess = false;
    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    isLoading = false;
    isSuccess = true;
    notifyListeners();
  }
}
