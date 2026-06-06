import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/models/login_response_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/services/auth_api_service.dart';
import 'package:mobile_app/services/nfc_service.dart';
import 'package:mobile_app/services/secure_storage_service.dart';
import 'package:mobile_app/models/verify_nfc_response_model.dart';

class AuthProvider extends ChangeNotifier {
  static const Duration _sessionDuration = Duration(minutes: 10);

  final AuthApiService _authApiService;
  final SecureStorageService _storageService;
  final NfcService _nfcService;
  Timer? _sessionTimer;

  bool isLoading = false;
  String? errorMessage;

  String? loginChallengeId;
  String? pendingPersonalNumber;
  UserModel? user;
  List<String> roles = [];
  String? jwt;

  AuthProvider({
    AuthApiService? authApiService,
    SecureStorageService? secureStorageService,
    required NfcService nfcService,
  }) : _authApiService = authApiService ?? AuthApiService(),
       _storageService = secureStorageService ?? SecureStorageService(),
       _nfcService = nfcService;

  bool get isAuthenticated => jwt != null;
  String get suggestedDebugToken =>
      pendingPersonalNumber == null ? 'NFC-1234' : 'NFC-$pendingPersonalNumber';

  Future<void> loadFromStorage() async {
    final storedJwt = await _storageService.readJwt();
    final storedUserJson = await _storageService.readUserJson();

    // Security requirement: no persisted login session across app exits.
    if (storedJwt != null || storedUserJson != null) {
      await _storageService.clearAll();
    }
  }

  Future<LoginResponseModel?> login({
    required String personalNumber,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authApiService.login(
        personalNumber: personalNumber,
        password: password,
      );
      pendingPersonalNumber = personalNumber;
      loginChallengeId = response.loginChallengeId;
      return response;
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Login fehlgeschlagen.');
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyNfc({String? manualToken}) async {
    if (loginChallengeId == null) {
      errorMessage = 'Keine Login-Challenge vorhanden.';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final token = manualToken ?? await _nfcService.scanToken();
      if (token == null || token.isEmpty) {
        errorMessage = 'Kein NFC-Token gelesen.';
        return false;
      }

      final response = await _authApiService.verifyNfc(
        loginChallengeId: loginChallengeId!,
        tokenIdentifier: token,
      );

      return _storeAuthenticatedUser(response);
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'NFC-Verifikation fehlgeschlagen.',
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _storeAuthenticatedUser(VerifyNfcResponseModel response) {
    jwt = response.jwt;
    user = response.user;
    roles = response.roles;
    pendingPersonalNumber = null;

    _startSessionTimer();

    notifyListeners();
    return true;
  }

  Future<void> logoutForAppBackground() async {
    if (!isAuthenticated) return;
    await _forceLogoutWithMessage('App verlassen: Bitte erneut anmelden.');
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionDuration, () {
      _forceLogoutWithMessage(
        'Sitzung nach 10 Minuten beendet. Bitte erneut anmelden.',
      );
    });
  }

  Future<void> _forceLogoutWithMessage(String message) async {
    await logout();
    errorMessage = message;
    notifyListeners();
  }

  Future<void> logout() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    jwt = null;
    user = null;
    roles = [];
    loginChallengeId = null;
    pendingPersonalNumber = null;
    errorMessage = null;
    await _storageService.clearAll();
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = jwt;
    if (token == null) {
      errorMessage = 'Nicht eingeloggt';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authApiService.changePassword(
        jwt: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(
        e,
        fallback: 'Passwort konnte nicht geändert werden.',
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Backend nicht erreichbar. Bitte Server-URL, WLAN und laufendes Backend prüfen.';
      }

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

  bool get isAdmin => roles.contains('ADMIN');

  // Hierarchy model:
  // - SOLDAT: soldier capabilities
  // - VORGESETZTER: approver + soldier capabilities
  // - ADMIN: administrative capabilities only
  bool get isSoldier =>
      roles.contains('SOLDAT') || roles.contains('VORGESETZTER');
  bool get isApprover =>
      roles.contains('GENEHMIGER') || roles.contains('VORGESETZTER');
}
