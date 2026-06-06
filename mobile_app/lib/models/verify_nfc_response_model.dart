import 'package:mobile_app/models/user_model.dart';

class VerifyNfcResponseModel {
  final String jwt;
  final UserModel user;
  final List<String> roles;
  final String? message;

  VerifyNfcResponseModel({
    required this.jwt,
    required this.user,
    required this.roles,
    this.message,
  });

  factory VerifyNfcResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyNfcResponseModel(
      jwt: json['jwt']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jwt': jwt,
      'user': user.toJson(),
      'roles': roles,
      'message': message,
    };
  }
}
