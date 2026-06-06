import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:mobile_app/models/admin_nfc_token_model.dart';
import 'package:mobile_app/models/admin_user_model.dart';
import 'package:mobile_app/models/audit_log_model.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/admin_api_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminApiService _apiService;
  AuthProvider _authProvider;
  Timer? _successMessageTimer;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;
  List<AdminUserModel> users = [];
  List<AdminNfcTokenModel> selectedUserTokens = [];
  String? selectedUserId;

  // Audit logs state
  bool isLoadingAuditLogs = false;
  List<AuditLog> auditLogs = [];
  int auditLogsTotal = 0;
  int auditLogsCurrentPage = 1;
  int auditLogsPageSize = 50;
  String? auditLogsActionFilter;
  String? auditLogsUserIdFilter;

  AdminProvider({
    required AuthProvider authProvider,
    AdminApiService? apiService,
  }) : _authProvider = authProvider,
       _apiService = apiService ?? AdminApiService();

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    isSubmitting = value;
    notifyListeners();
  }

  String? _jwtOrSetError() {
    final jwt = _authProvider.jwt;
    if (jwt == null) {
      errorMessage = 'Nicht eingeloggt';
      notifyListeners();
      return null;
    }

    return jwt;
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

  void clearMessages() {
    _successMessageTimer?.cancel();
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  void _setSuccessMessage(String message) {
    _successMessageTimer?.cancel();
    successMessage = message;
    notifyListeners();

    _successMessageTimer = Timer(const Duration(seconds: 4), () {
      successMessage = null;
      notifyListeners();
    });
  }

  Future<void> loadUsers() async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return;
    }

    _setLoading(true);
    errorMessage = null;

    try {
      users = await _apiService.getUsers(jwt);

      if (selectedUserId != null &&
          users.every((x) => x.id != selectedUserId)) {
        selectedUserId = null;
        selectedUserTokens = [];
      }
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnten nicht geladen werden.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectUser(String userId) async {
    selectedUserId = userId;
    notifyListeners();
    await loadSelectedUserTokens();
  }

  Future<void> loadSelectedUserTokens() async {
    final jwt = _jwtOrSetError();
    if (jwt == null || selectedUserId == null) {
      return;
    }

    _setLoading(true);
    errorMessage = null;

    try {
      selectedUserTokens = await _apiService.getUserNfcTokens(
        jwt: jwt,
        userId: selectedUserId!,
      );
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Tokens konnten nicht geladen werden.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUser({
    required String personalNumber,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String unit,
    required String rank,
    required String initialPassword,
    required List<String> roles,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.createUser(
        jwt: jwt,
        personalNumber: personalNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        unit: unit,
        rank: rank,
        initialPassword: initialPassword,
        roles: roles,
      );
      _setSuccessMessage('Nutzer wurde erstellt.');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnte nicht erstellt werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String personalNumber,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String unit,
    required String rank,
    required List<String> roles,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.updateUser(
        jwt: jwt,
        userId: userId,
        personalNumber: personalNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        unit: unit,
        rank: rank,
        roles: roles,
      );
      _setSuccessMessage('Nutzerdaten wurden aktualisiert.');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnte nicht aktualisiert werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> blockUser(String userId) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.blockUser(jwt: jwt, userId: userId);
      _setSuccessMessage('Nutzer wurde gesperrt.');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnte nicht gesperrt werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> unblockUser(String userId) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.unblockUser(jwt: jwt, userId: userId);
      _setSuccessMessage('Nutzer wurde entsperrt.');
      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnte nicht entsperrt werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.resetPassword(
        jwt: jwt,
        userId: userId,
        newPassword: newPassword,
      );
      _setSuccessMessage('Passwort wurde zurückgesetzt.');
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Passwort konnte nicht zurückgesetzt werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteUser(String userId) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.deleteUser(jwt: jwt, userId: userId);

      _setSuccessMessage('Nutzer wurde gelöscht.');

      if (selectedUserId == userId) {
        selectedUserId = null;
        selectedUserTokens = [];
      }

      await loadUsers();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Nutzer konnte nicht gelöscht werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> issueNfcToken({
    required String userId,
    required String tokenIdentifier,
    required bool revokeCurrentActive,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.issueNfcToken(
        jwt: jwt,
        userId: userId,
        tokenIdentifier: tokenIdentifier,
        revokeCurrentActive: revokeCurrentActive,
      );

      _setSuccessMessage('NFC-Token wurde vergeben.');
      await loadUsers();

      if (selectedUserId == userId) {
        await loadSelectedUserTokens();
      }

      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Token konnte nicht vergeben werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> reassignNfcToken({
    required String userId,
    required String newTokenIdentifier,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.reassignNfcToken(
        jwt: jwt,
        userId: userId,
        newTokenIdentifier: newTokenIdentifier,
      );

      _setSuccessMessage('NFC-Token wurde neu vergeben.');
      await loadUsers();

      if (selectedUserId == userId) {
        await loadSelectedUserTokens();
      }

      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Token konnte nicht neu vergeben werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> blockNfcToken({required String tokenId}) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.blockNfcToken(jwt: jwt, tokenId: tokenId);

      _setSuccessMessage('NFC-Token wurde gesperrt.');
      await loadUsers();
      await loadSelectedUserTokens();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Token konnte nicht gesperrt werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> deleteNfcToken({required String tokenId}) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return false;
    }

    _setSubmitting(true);
    errorMessage = null;
    successMessage = null;

    try {
      await _apiService.deleteNfcToken(jwt: jwt, tokenId: tokenId);

      _setSuccessMessage('NFC-Token wurde gelöscht.');
      await loadUsers();
      await loadSelectedUserTokens();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Token konnte nicht gelöscht werden.',
      );
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> loadAuditLogs({
    int page = 1,
    String? actionType,
    String? userId,
  }) async {
    final jwt = _jwtOrSetError();
    if (jwt == null) {
      return;
    }

    isLoadingAuditLogs = true;
    errorMessage = null;
    auditLogsCurrentPage = page;
    auditLogsActionFilter = actionType;
    auditLogsUserIdFilter = userId;
    notifyListeners();

    try {
      final response = await _apiService.getAuditLogs(
        jwt: jwt,
        page: page,
        pageSize: auditLogsPageSize,
        actionType: actionType,
        userId: userId,
      );

      auditLogs = response.items;
      auditLogsTotal = response.total;
      notifyListeners();
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Audit-Protokolle konnten nicht geladen werden.',
      );
      notifyListeners();
    } finally {
      isLoadingAuditLogs = false;
      notifyListeners();
    }
  }

  void clearAuditLogsFilters() {
    auditLogsActionFilter = null;
    auditLogsUserIdFilter = null;
    auditLogsCurrentPage = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _successMessageTimer?.cancel();
    super.dispose();
  }
}
