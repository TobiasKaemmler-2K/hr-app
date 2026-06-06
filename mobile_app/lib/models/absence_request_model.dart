import 'package:mobile_app/models/absence_type_model.dart';

enum AbsenceStatus { pending, approved, rejected, cancelled }

class AbsenceRequestModel {
  final String id;
  final AbsenceTypeModel type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final AbsenceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? requestedByName;
  final String? requestedByPersonalNumber;

  AbsenceRequestModel({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.requestedByName,
    this.requestedByPersonalNumber,
  });

  factory AbsenceRequestModel.fromJson(Map<String, dynamic> json) {
    AbsenceStatus parseStatus(String? status) {
      switch (status?.toLowerCase()) {
        case 'approved':
          return AbsenceStatus.approved;
        case 'rejected':
          return AbsenceStatus.rejected;
        case 'cancelled':
          return AbsenceStatus.cancelled;
        default:
          return AbsenceStatus.pending;
      }
    }

    return AbsenceRequestModel(
      id: json['id']?.toString() ?? '',
      type: AbsenceTypeModel.fromJson(json['type'] as Map<String, dynamic>? ?? {}),
      startDate: DateTime.parse(json['startDate']?.toString() ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate']?.toString() ?? DateTime.now().toIso8601String()),
      reason: json['reason']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      requestedByName: json['requestedByName']?.toString(),
      requestedByPersonalNumber: json['requestedByPersonalNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString(AbsenceStatus status) {
      switch (status) {
        case AbsenceStatus.approved:
          return 'approved';
        case AbsenceStatus.rejected:
          return 'rejected';
        case AbsenceStatus.cancelled:
          return 'cancelled';
        default:
          return 'pending';
      }
    }

    return {
      'id': id,
      'type': type.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'requestedByName': requestedByName,
      'requestedByPersonalNumber': requestedByPersonalNumber,
    };
  }
}
