class AuthenticatedUserModel {
  String userId;
  String userName;
  List<String> roles;

  AuthenticatedUserModel({required this.userId, required this.userName, required this.roles});
  
  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUserModel(
      userId: json['userId'],
      userName: json['userName'],
      roles: List<String>.from(json['roles']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'roles': roles,
    };
  }
}