class AbsenceRequestModel {
  final int id;
  final String userId;
  final int absenceTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? approvedBy;
  final String? approvalReason;

  AbsenceRequestModel({
    required this.id,
    required this.userId,
    required this.absenceTypeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.approvedBy,
    this.approvalReason,
  });
}