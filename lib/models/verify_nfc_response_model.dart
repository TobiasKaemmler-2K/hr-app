class VerifyNfcResponseModel {
  final String token;
  final String user;

  VerifyNfcResponseModel({required this.token, required this.user});

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user,
    };
  }

  factory VerifyNfcResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyNfcResponseModel(
      token: json['token'],
      user: json['user'],
    );
  }
}