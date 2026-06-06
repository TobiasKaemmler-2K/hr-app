class UserModel {
  final String id;
  final String personalNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String rank;
  final String unit;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.personalNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.rank,
    required this.unit,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      personalNumber: json['personalNumber']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personalNumber': personalNumber,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'rank': rank,
      'unit': unit,
      'roles': roles,
    };
  }
}
