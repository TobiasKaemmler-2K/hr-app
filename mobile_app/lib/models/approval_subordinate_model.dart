class ApprovalSubordinateModel {
  final String id;
  final String personalNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String rank;
  final String unit;

  const ApprovalSubordinateModel({
    required this.id,
    required this.personalNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.rank,
    required this.unit,
  });

  String get displayName => '$firstName $lastName';

  factory ApprovalSubordinateModel.fromJson(Map<String, dynamic> json) {
    return ApprovalSubordinateModel(
      id: json['id']?.toString() ?? '',
      personalNumber: json['personalNumber']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
    );
  }
}
