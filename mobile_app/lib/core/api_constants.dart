class ApiConstants {
  // Optional override, e.g. --dart-define=API_BASE_URL=http://192.168.178.44:5203
  static const String _baseUrlFromEnvironment = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _defaultLanBaseUrl = 'http://192.168.178.36:5203';

  static String get baseUrl {
    final override = _baseUrlFromEnvironment.trim();
    if (override.isNotEmpty) {
      return override;
    }

    return _defaultLanBaseUrl;
  }

  static String authLogin = '/api/auth/login';
  static String authVerifyNfc = '/api/auth/verify-nfc';
  static String authChangePassword = '/api/auth/change-password';

  static String absencesMy = '/api/absences/my';
  static String absencesCreate = '/api/absences';
  static String absencesTypes = '/api/absences/types';
  static String absencesCancel(String id) => '/api/absences/$id/cancel';

  static String approvalsPending = '/api/approvals/pending';
  static String approvalsApproved = '/api/approvals/approved';
  static String approvalsSubordinates = '/api/approvals/subordinates';
  static String approvalsSubordinateRequests(String id) =>
      '/api/approvals/subordinates/$id/requests';
  static String approvalsApprove(String id) => '/api/approvals/$id/approve';
  static String approvalsReject(String id) => '/api/approvals/$id/reject';

  static String adminUsers = '/api/admin/users';
  static String adminUser(String id) => '/api/admin/users/$id';
  static String adminBlockUser(String id) => '/api/admin/users/$id/block';
  static String adminUnblockUser(String id) => '/api/admin/users/$id/unblock';
  static String adminResetPassword(String id) =>
      '/api/admin/users/$id/reset-password';

  static String adminUserNfcTokens(String userId) =>
      '/api/admin/users/$userId/nfc-tokens';
  static String adminReassignNfcToken(String userId) =>
      '/api/admin/users/$userId/nfc-tokens/reassign';
  static String adminBlockNfcToken(String tokenId) =>
      '/api/admin/nfc-tokens/$tokenId/block';
  static String adminDeleteNfcToken(String tokenId) =>
      '/api/admin/nfc-tokens/$tokenId';
  static String adminAuditLogs = '/api/admin/audit-logs';
}
