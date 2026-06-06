import 'dart:async';

import 'nfc_service.dart';

class MockOrManualNfcService implements NfcService {
  static const List<String> builtInTestTokens = [
    'NFC-1234',
  ];

  String? _manualToken = 'NFC-1234';

  /// Sets a token that will be returned by [scanToken].
  void setManualToken(String? token) {
    _manualToken = token;
  }

  /// Returns the manual token if set, otherwise null.
  @override
  Future<String?> scanToken() async {
    // In debug mode, return the currently configured manual token.
    return _manualToken;
  }
}
