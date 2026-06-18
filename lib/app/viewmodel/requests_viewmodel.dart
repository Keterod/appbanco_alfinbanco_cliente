import 'package:flutter/foundation.dart';

import '../model/request_model.dart';
import '../repository/requests_repository.dart';

class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel({RequestsRepository? requestsRepository})
      : _repository = requestsRepository ?? RequestsRepository();

  final RequestsRepository _repository;

  bool isLoading = false;
  bool isRefreshing = false;
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

  Future<bool> refresh() async {
    isRefreshing = true;
    notifyListeners();

    try {
      final result = await _repository.getRequests();
      requests = result;
      errorMessage = null;
      isRefreshing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[RequestsViewModel] refresh error: $e');
      isRefreshing = false;
      notifyListeners();
      return false;
    }
  }
}
