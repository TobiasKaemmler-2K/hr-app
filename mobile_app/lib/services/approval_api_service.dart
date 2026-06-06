import 'package:dio/dio.dart';
import 'package:mobile_app/core/api_constants.dart';
import 'package:mobile_app/models/absence_request_model.dart';
import 'package:mobile_app/models/approval_subordinate_model.dart';

class ApprovalApiService {
  final Dio _dio;

  ApprovalApiService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Options _authOptions(String jwt) {
    return Options(headers: {'Authorization': 'Bearer $jwt'});
  }

  Future<List<AbsenceRequestModel>> getPendingApprovals(String jwt) async {
    final response = await _dio.get(
      ApiConstants.approvalsPending,
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AbsenceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AbsenceRequestModel>> getApprovedApprovals(String jwt) async {
    final response = await _dio.get(
      ApiConstants.approvalsApproved,
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AbsenceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApprovalSubordinateModel>> getSubordinates(String jwt) async {
    final response = await _dio.get(
      ApiConstants.approvalsSubordinates,
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => ApprovalSubordinateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AbsenceRequestModel>> getSubordinateRequests({
    required String jwt,
    required String subordinateId,
  }) async {
    final response = await _dio.get(
      ApiConstants.approvalsSubordinateRequests(subordinateId),
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AbsenceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve({
    required String jwt,
    required String requestId,
    String? comment,
  }) async {
    await _dio.post(
      ApiConstants.approvalsApprove(requestId),
      options: _authOptions(jwt),
      data: {
        'comment': comment,
      },
    );
  }

  Future<void> reject({
    required String jwt,
    required String requestId,
    String? comment,
  }) async {
    await _dio.post(
      ApiConstants.approvalsReject(requestId),
      options: _authOptions(jwt),
      data: {
        'comment': comment,
      },
    );
  }
}
