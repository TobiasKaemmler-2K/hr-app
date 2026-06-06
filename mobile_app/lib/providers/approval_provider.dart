import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/models/approval_subordinate_model.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/approval_api_service.dart';

class ApprovalProvider extends ChangeNotifier {
  final ApprovalApiService _apiService;
  AuthProvider _authProvider;

  bool isLoading = false;
  String? errorMessage;

  List<AbsenceRequestModel> pendingApprovals = [];
  List<AbsenceRequestModel> approvedApprovals = [];
  List<ApprovalSubordinateModel> subordinates = [];

  ApprovalProvider({
    required AuthProvider authProvider,
    ApprovalApiService? apiService,
  })  : _authProvider = authProvider,
        _apiService = apiService ?? ApprovalApiService();

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> loadPendingApprovals() async {
    final jwt = _authProvider.jwt;
    if (jwt == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      pendingApprovals = await _apiService.getPendingApprovals(jwt);
      approvedApprovals = await _apiService.getApprovedApprovals(jwt);
      subordinates = await _apiService.getSubordinates(jwt);
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Genehmigungsdaten konnten nicht geladen werden.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AbsenceRequestModel>> loadSubordinateRequests(String subordinateId) async {
    final jwt = _authProvider.jwt;
    if (jwt == null) {
      throw Exception('Nicht eingeloggt');
    }

    return _apiService.getSubordinateRequests(jwt: jwt, subordinateId: subordinateId);
  }

  Future<bool> approve({
    required String requestId,
    String? comment,
  }) async {
    final jwt = _authProvider.jwt;
    if (jwt == null) {
      errorMessage = 'Nicht eingeloggt';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.approve(jwt: jwt, requestId: requestId, comment: comment);
      final index = pendingApprovals.indexWhere((r) => r.id == requestId);
      if (index >= 0) {
        final request = pendingApprovals[index];
        pendingApprovals.removeAt(index);
        approvedApprovals.insert(
          0,
          AbsenceRequestModel(
            id: request.id,
            type: request.type,
            startDate: request.startDate,
            endDate: request.endDate,
            reason: request.reason,
            status: AbsenceStatus.approved,
            createdAt: request.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Antrag konnte nicht genehmigt werden.');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reject({
    required String requestId,
    String? comment,
  }) async {
    final jwt = _authProvider.jwt;
    if (jwt == null) {
      errorMessage = 'Nicht eingeloggt';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _apiService.reject(jwt: jwt, requestId: requestId, comment: comment);
      pendingApprovals.removeWhere((r) => r.id == requestId);
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Antrag konnte nicht abgelehnt werden.');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        final message = responseData['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }

      if (responseData is String && responseData.trim().isNotEmpty) {
        return responseData;
      }
    }

    return fallback;
  }
}
