import 'package:mobile_app/models/admin_nfc_token_model.dart';

class AdminUserModel {
  final String id;
  final String personalNumber;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String unit;
  final String rank;
  final bool isActive;
  final List<String> roles;
  final AdminNfcTokenModel? activeNfcToken;
  final String? lockReason;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUserModel({
    required this.id,
    required this.personalNumber,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.unit,
    required this.rank,
    required this.isActive,
    required this.roles,
    required this.activeNfcToken,
    required this.lockReason,
    required this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => '$firstName $lastName';

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      personalNumber: json['personalNumber']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
      isActive: json['isActive'] == true,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      activeNfcToken: json['activeNfcToken'] is Map<String, dynamic>
          ? AdminNfcTokenModel.fromJson(
              json['activeNfcToken'] as Map<String, dynamic>,
            )
          : null,
      lockReason: json['lockReason']?.toString(),
      lockedAt: DateTime.tryParse(json['lockedAt']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
