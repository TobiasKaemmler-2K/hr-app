import 'package:dio/dio.dart';
import 'package:mobile_app/core/api_constants.dart';
import 'package:mobile_app/models/admin_nfc_token_model.dart';
import 'package:mobile_app/models/admin_user_model.dart';
import 'package:mobile_app/models/audit_log_model.dart';

class AdminApiService {
  final Dio _dio;

  AdminApiService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Options _authOptions(String jwt) {
    return Options(headers: {'Authorization': 'Bearer $jwt'});
  }

  Future<List<AdminUserModel>> getUsers(String jwt) async {
    final response = await _dio.get(
      ApiConstants.adminUsers,
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUserModel> createUser({
    required String jwt,
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
    final response = await _dio.post(
      ApiConstants.adminUsers,
      options: _authOptions(jwt),
      data: {
        'personalNumber': personalNumber,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'unit': unit,
        'rank': rank,
        'initialPassword': initialPassword,
        'roles': roles,
      },
    );

    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserModel> updateUser({
    required String jwt,
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
    final response = await _dio.put(
      ApiConstants.adminUser(userId),
      options: _authOptions(jwt),
      data: {
        'personalNumber': personalNumber,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'unit': unit,
        'rank': rank,
        'roles': roles,
      },
    );

    return AdminUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> blockUser({required String jwt, required String userId}) async {
    await _dio.post(
      ApiConstants.adminBlockUser(userId),
      options: _authOptions(jwt),
    );
  }

  Future<void> unblockUser({
    required String jwt,
    required String userId,
  }) async {
    await _dio.post(
      ApiConstants.adminUnblockUser(userId),
      options: _authOptions(jwt),
    );
  }

  Future<void> resetPassword({
    required String jwt,
    required String userId,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConstants.adminResetPassword(userId),
      options: _authOptions(jwt),
      data: {'newPassword': newPassword},
    );
  }

  Future<void> deleteUser({required String jwt, required String userId}) async {
    await _dio.delete(
      ApiConstants.adminUser(userId),
      options: _authOptions(jwt),
    );
  }

  Future<List<AdminNfcTokenModel>> getUserNfcTokens({
    required String jwt,
    required String userId,
  }) async {
    final response = await _dio.get(
      ApiConstants.adminUserNfcTokens(userId),
      options: _authOptions(jwt),
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AdminNfcTokenModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminNfcTokenModel> issueNfcToken({
    required String jwt,
    required String userId,
    required String tokenIdentifier,
    required bool revokeCurrentActive,
  }) async {
    final response = await _dio.post(
      ApiConstants.adminUserNfcTokens(userId),
      options: _authOptions(jwt),
      data: {
        'tokenIdentifier': tokenIdentifier,
        'revokeCurrentActive': revokeCurrentActive,
      },
    );

    return AdminNfcTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminNfcTokenModel> reassignNfcToken({
    required String jwt,
    required String userId,
    required String newTokenIdentifier,
  }) async {
    final response = await _dio.post(
      ApiConstants.adminReassignNfcToken(userId),
      options: _authOptions(jwt),
      data: {'newTokenIdentifier': newTokenIdentifier},
    );

    return AdminNfcTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> blockNfcToken({
    required String jwt,
    required String tokenId,
  }) async {
    await _dio.post(
      ApiConstants.adminBlockNfcToken(tokenId),
      options: _authOptions(jwt),
    );
  }

  Future<void> deleteNfcToken({
    required String jwt,
    required String tokenId,
  }) async {
    await _dio.delete(
      ApiConstants.adminDeleteNfcToken(tokenId),
      options: _authOptions(jwt),
    );
  }

  Future<AuditLogsResponse> getAuditLogs({
    required String jwt,
    int page = 1,
    int pageSize = 50,
    String? actionType,
    String? userId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (actionType != null && actionType.isNotEmpty) {
      queryParams['actionType'] = actionType;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams['userId'] = userId;
    }

    final response = await _dio.get(
      ApiConstants.adminAuditLogs,
      options: _authOptions(jwt),
      queryParameters: queryParams,
    );

    return AuditLogsResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
