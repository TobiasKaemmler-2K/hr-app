import 'package:mobile_app/models/user_model.dart';

class AuthenticatedUserModel {
  final String jwt;
  final UserModel user;
  final List<String> roles;

  AuthenticatedUserModel({
    required this.jwt,
    required this.user,
    required this.roles,
  });

  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserModel(
      jwt: json['jwt']?.toString() ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jwt': jwt,
      'user': user.toJson(),
      'roles': roles,
    };
  }
}
