class AdminNfcTokenModel {
  final String id;
  final String userId;
  final String tokenIdentifier;
  final bool isActive;
  final DateTime issuedAt;
  final DateTime? revokedAt;

  const AdminNfcTokenModel({
    required this.id,
    required this.userId,
    required this.tokenIdentifier,
    required this.isActive,
    required this.issuedAt,
    required this.revokedAt,
  });

  factory AdminNfcTokenModel.fromJson(Map<String, dynamic> json) {
    return AdminNfcTokenModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      tokenIdentifier: json['tokenIdentifier']?.toString() ?? '',
      isActive: json['isActive'] == true,
      issuedAt:
          DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      revokedAt: DateTime.tryParse(json['revokedAt']?.toString() ?? ''),
    );
  }
}
