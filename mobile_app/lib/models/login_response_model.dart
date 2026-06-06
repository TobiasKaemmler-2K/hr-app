class LoginResponseModel {
  final bool requiresNfc;
  final String loginChallengeId;
  final String? message;

  LoginResponseModel({
    required this.requiresNfc,
    required this.loginChallengeId,
    this.message,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      requiresNfc: json['requiresNfc'] == true,
      loginChallengeId: json['loginChallengeId']?.toString() ?? '',
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiresNfc': requiresNfc,
      'loginChallengeId': loginChallengeId,
      'message': message,
    };
  }
}
