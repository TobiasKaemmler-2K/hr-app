import 'package:dio/dio.dart';
import 'package:mobile_app/core/api_constants.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/models/absence_type_model.dart';

class AbsenceApiService {
  final Dio _dio;

  AbsenceApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Options _authOptions(String jwt) {
    return Options(headers: {'Authorization': 'Bearer $jwt'});
  }

  Future<List<AbsenceRequestModel>> getMyAbsences(String jwt) async {
    final response = await _dio.get(
      ApiConstants.absencesMy,
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AbsenceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AbsenceTypeModel>> getAbsenceTypes(String jwt) async {
    try {
      final response = await _dio.get(
        ApiConstants.absencesTypes,
        options: _authOptions(jwt),
      );

      final data = response.data as List<dynamic>;
      return data
          .map((e) => AbsenceTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback for backends exposing absence types via /api/absence-types.
      final response = await _dio.get(
        '/api/absence-types',
        options: _authOptions(jwt),
      );

      final data = response.data as List<dynamic>;
      return data
          .map((e) => AbsenceTypeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<AbsenceRequestModel> createAbsence({
    required String jwt,
    required String typeId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final response = await _dio.post(
      ApiConstants.absencesCreate,
      options: _authOptions(jwt),
      data: {
        'absenceTypeId': typeId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      },
    );

    return AbsenceRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelAbsence({
    required String jwt,
    required String absenceId,
  }) async {
    await _dio.post(
      ApiConstants.absencesCancel(absenceId),
      options: _authOptions(jwt),
    );
  }
}
