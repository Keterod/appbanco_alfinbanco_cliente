import 'package:flutter/foundation.dart';

import '../model/request_model.dart';
import '../repository/requests_repository.dart';

class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel({RequestsRepository? requestsRepository})
      : _repository = requestsRepository ?? RequestsRepository();

  final RequestsRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  List<RequestModel> requests = [];

  Future<void> loadRequests() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getRequests();
      requests = result;
    } catch (e) {
      errorMessage = 'No se pudieron cargar las solicitudes.';
      debugPrint('[RequestsViewModel] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadRequests();
  }
}
