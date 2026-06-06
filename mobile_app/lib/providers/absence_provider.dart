import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/models/absence_type_model.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/absence_api_service.dart';

class AbsenceProvider extends ChangeNotifier {
  static const int yearlyVacationAllowanceDays = 30;

  final AbsenceApiService _apiService;
  AuthProvider _authProvider;

  bool isLoading = false;
  String? errorMessage;

  List<AbsenceRequestModel> myAbsences = [];
  List<AbsenceTypeModel> absenceTypes = [];

  int get currentYear => DateTime.now().year;
  int get previousYear => currentYear - 1;

  int get bookedVacationDaysCurrentYear {
    return bookedVacationDaysForYear(currentYear);
  }

  int get approvedVacationDaysCurrentYear {
    return approvedVacationDaysForYear(currentYear);
  }

  int get remainingVacationDaysCurrentYear {
    return remainingVacationDaysForYear(currentYear);
  }

  int bookedVacationDaysForYear(int year) {
    return myAbsences
        .where((absence) => _isVacation(absence.type.name))
        .where((absence) =>
            absence.status == AbsenceStatus.pending ||
            absence.status == AbsenceStatus.approved)
        .map((absence) => _overlappingWeekdaysInYear(absence, year))
        .fold<int>(0, (sum, days) => sum + days);
  }

  int approvedVacationDaysForYear(int year) {
    return myAbsences
        .where((absence) => _isVacation(absence.type.name))
        .where((absence) => absence.status == AbsenceStatus.approved)
        .map((absence) => _overlappingWeekdaysInYear(absence, year))
        .fold<int>(0, (sum, days) => sum + days);
  }

  int remainingVacationDaysForYear(int year) {
    return math.max(0, yearlyVacationAllowanceDays - bookedVacationDaysForYear(year));
  }

  int get openAbsenceRequestsCount {
    return myAbsences.where((absence) => absence.status == AbsenceStatus.pending).length;
  }

  AbsenceProvider({
    required AuthProvider authProvider,
    AbsenceApiService? apiService,
  })  : _authProvider = authProvider,
        _apiService = apiService ?? AbsenceApiService();

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> loadMyAbsences() async {
    final jwt = _authProvider.jwt;
    if (jwt == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      myAbsences = await _apiService.getMyAbsences(jwt);
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Meine Abwesenheiten konnten nicht geladen werden.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAbsenceTypes() async {
    final jwt = _authProvider.jwt;
    if (jwt == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      absenceTypes = await _apiService.getAbsenceTypes(jwt);
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Abwesenheitsarten konnten nicht geladen werden.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAbsence({
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
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
      final newRequest = await _apiService.createAbsence(
        jwt: jwt,
        typeId: typeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );

      myAbsences.insert(0, newRequest);
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Antrag konnte nicht erstellt werden.');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAbsence(String absenceId) async {
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
      await _apiService.cancelAbsence(jwt: jwt, absenceId: absenceId);
      myAbsences.removeWhere((element) => element.id == absenceId);
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e, fallback: 'Antrag konnte nicht storniert werden.');
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

  bool _isVacation(String typeName) {
    return typeName.toLowerCase().contains('urlaub');
  }

  int _overlappingWeekdaysInYear(AbsenceRequestModel absence, int year) {
    final rangeStart = DateTime(year, 1, 1);
    final rangeEnd = DateTime(year, 12, 31, 23, 59, 59);

    final absenceStart = DateTime(absence.startDate.year, absence.startDate.month, absence.startDate.day);
    final absenceEnd = DateTime(absence.endDate.year, absence.endDate.month, absence.endDate.day, 23, 59, 59);

    final effectiveStart = absenceStart.isBefore(rangeStart) ? rangeStart : absenceStart;
    final effectiveEnd = absenceEnd.isAfter(rangeEnd) ? rangeEnd : absenceEnd;

    if (effectiveEnd.isBefore(effectiveStart)) {
      return 0;
    }

    return _countWeekdaysInclusive(effectiveStart, effectiveEnd);
  }

  int _countWeekdaysInclusive(DateTime start, DateTime end) {
    var cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    var weekdays = 0;

    while (!cursor.isAfter(last)) {
      final day = cursor.weekday;
      if (day >= DateTime.monday && day <= DateTime.friday) {
        weekdays += 1;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return weekdays;
  }
}
