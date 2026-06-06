class AuditLog {
  final String id;
  final String? userId;
  final String userDisplay;
  final String actionType;
  final String? actionDetails;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userDisplay,
    required this.actionType,
    required this.actionDetails,
    required this.ipAddress,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      userDisplay: json['userDisplay'] as String? ?? 'Unknown',
      actionType: json['actionType'] as String? ?? '',
      actionDetails: json['actionDetails'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplay': userDisplay,
      'actionType': actionType,
      'actionDetails': actionDetails,
      'ipAddress': ipAddress,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AuditLogsResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<AuditLog> items;

  AuditLogsResponse({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogsResponse(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 50,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => AuditLog.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'pageSize': pageSize,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
