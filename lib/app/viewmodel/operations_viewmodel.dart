import 'package:flutter/foundation.dart';

import '../model/operation_model.dart';
import '../repository/auth_repository.dart';
import '../repository/operations_repository.dart';

class OperationsViewModel extends ChangeNotifier {
  OperationsViewModel({
    AuthRepository? authRepository,
    OperationsRepository? operationsRepository,
  })  : _auth = authRepository ?? AuthRepository(),
        _operationsRepository =
            operationsRepository ?? OperationsRepository();

  final AuthRepository _auth;
  final OperationsRepository _operationsRepository;

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  List<OperationModel> operations = [];

  Future<void> loadOperations() async {
    if (!_auth.isConfigured || _auth.currentUser == null) {
      errorMessage = 'No hay sesión activa.';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _operationsRepository.getOperations();
      operations = result;
    } catch (e) {
      errorMessage = 'No se pudieron cargar las operaciones.';
      debugPrint('[OperationsViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> refresh() async {
    isRefreshing = true;
    notifyListeners();

    try {
      final result = await _operationsRepository.getOperations();
      operations = result;
      errorMessage = null;
      isRefreshing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[OperationsViewModel] refresh error: $e');
      isRefreshing = false;
      notifyListeners();
      return false;
    }
  }
}
