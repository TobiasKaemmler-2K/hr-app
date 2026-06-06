class LoginResponseModel {
  final bool requiresNfc;
  final String loginChallengeId;

  LoginResponseModel({required this.requiresNfc, required this.loginChallengeId});
}