import 'package:dio/dio.dart';
import 'package:mobile_app/core/api_constants.dart';
import 'package:mobile_app/models/login_response_model.dart';
import 'package:mobile_app/models/verify_nfc_response_model.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

  Future<LoginResponseModel> login({
    required String personalNumber,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.authLogin,
      data: {
        'personalNumber': personalNumber,
        'password': password,
      },
    );

    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VerifyNfcResponseModel> verifyNfc({
    required String loginChallengeId,
    required String tokenIdentifier,
  }) async {
    final response = await _dio.post(
      ApiConstants.authVerifyNfc,
      data: {
        'loginChallengeId': loginChallengeId,
        'tokenIdentifier': tokenIdentifier,
      },
    );

    return VerifyNfcResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String jwt,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConstants.authChangePassword,
      options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
