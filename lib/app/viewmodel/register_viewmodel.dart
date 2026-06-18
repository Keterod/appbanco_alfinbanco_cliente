import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/register_model.dart';
import '../repository/auth_repository.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  String dni = '';
  String firstName = '';
  String lastName = '';
  String phone = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool acceptedTerms = false;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  RegisterModel? lastRegistered;

  void setDni(String value) {
    dni = value;
    notifyListeners();
  }

  void setFirstName(String value) {
    firstName = value;
    notifyListeners();
  }

  void setLastName(String value) {
    lastName = value;
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value;
    notifyListeners();
  }

  void setEmail(String value) {
    email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    confirmPassword = value;
    notifyListeners();
  }

  void toggleAcceptedTerms(bool value) {
    acceptedTerms = value;
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  bool validate() {
    clearMessages();
    final errors = <String>[];

    final dniDigits = dni.replaceAll(RegExp(r'\D'), '');
    if (dniDigits.length != 8) {
      errors.add('El DNI debe tener 8 dígitos.');
    }

    if (firstName.trim().isEmpty) {
      errors.add('Los nombres son obligatorios.');
    }

    if (lastName.trim().isEmpty) {
      errors.add('Los apellidos son obligatorios.');
    }

    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length != 9) {
      errors.add('El teléfono debe tener 9 dígitos.');
    }

    final emailTrimmed = email.trim();
    if (emailTrimmed.isEmpty) {
      errors.add('El correo es obligatorio.');
    } else if (!_isValidEmail(emailTrimmed)) {
      errors.add('Ingrese un correo válido.');
    }

    if (password.length < 6) {
      errors.add('La contraseña debe tener al menos 6 caracteres.');
    }

    if (password != confirmPassword) {
      errors.add('Las contraseñas no coinciden.');
    }

    if (!acceptedTerms) {
      errors.add('Debe aceptar los términos y condiciones.');
    }

    if (errors.isNotEmpty) {
      errorMessage = errors.join('\n');
      notifyListeners();
      return false;
    }

    return true;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[\w.\-]+@[\w.\-]+\.\w{2,}$').hasMatch(value);
  }

  Future<bool> register() async {
    if (!validate()) return false;

    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final dniDigits = dni.replaceAll(RegExp(r'\D'), '');
    final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
    final emailTrimmed = email.trim();

    lastRegistered = RegisterModel(
      dni: dniDigits,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phoneDigits,
      email: emailTrimmed,
      password: password,
      acceptedTerms: acceptedTerms,
      createdAt: DateTime.now(),
    );

    if (_authRepository.isConfigured) {
      try {
        await _authRepository.signUpClient(
          email: emailTrimmed,
          password: password,
          dni: dniDigits,
          nombres: firstName.trim(),
          apellidos: lastName.trim(),
          telefono: phoneDigits,
          direccion: '',
          tipoCliente: 'Cliente',
        );
        await _authRepository.signOut();

        isLoading = false;
        successMessage =
            'Cuenta creada correctamente. Inicia sesión con tu correo.';
        notifyListeners();
        return true;
      } on AuthException catch (e, stackTrace) {
        debugPrint('DEBUG REGISTER: tipo=${e.runtimeType}');
        debugPrint('DEBUG REGISTER: mensaje=${e.message}');
        debugPrint('DEBUG REGISTER: statusCode=${e.statusCode}');
        debugPrint('DEBUG REGISTER: code=${e.code}');
        debugPrint('DEBUG REGISTER: stackTrace=$stackTrace');
        errorMessage = _mapRegisterError(e.message);
      } on PostgrestException catch (e, stackTrace) {
        debugPrint('DEBUG REGISTER: tipo=${e.runtimeType}');
        debugPrint('DEBUG REGISTER: mensaje=${e.message}');
        debugPrint('DEBUG REGISTER: code=${e.code}');
        debugPrint('DEBUG REGISTER: details=${e.details}');
        debugPrint('DEBUG REGISTER: hint=${e.hint}');
        debugPrint('DEBUG REGISTER: stackTrace=$stackTrace');
        errorMessage = _mapRegisterError(e.message);
      } catch (e, stackTrace) {
        debugPrint('DEBUG REGISTER: tipo=${e.runtimeType}');
        debugPrint('DEBUG REGISTER: mensaje=$e');
        debugPrint('DEBUG REGISTER: stackTrace=$stackTrace');
        errorMessage = _mapRegisterError(e.toString());
      }

      isLoading = false;
      notifyListeners();
      return false;
    }

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    isLoading = false;
    successMessage =
        'Cuenta creada correctamente. Inicia sesión con tu correo.';
    notifyListeners();
    return true;
  }

  String _mapRegisterError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('already') || msg.contains('registered')) {
      return 'Este correo ya está registrado.';
    }
    if (msg.contains('password')) {
      return 'La contraseña no cumple los requisitos de seguridad.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Verifica tu conexión e intenta de nuevo.';
    }
    if (msg.contains('pgrst') || msg.contains('relation') || msg.contains('table')) {
      return 'El servidor aún no tiene las tablas configuradas. Contacta al administrador.';
    }
    return 'No se pudo crear la cuenta. Intenta más tarde.';
  }
}
