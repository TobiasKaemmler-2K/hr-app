abstract class NfcService {
  /// Starts an NFC scan and returns a token identifier if a tag is found.
  ///
  /// Returns `null` when the scan is cancelled or no valid token is read.
  Future<String?> scanToken();
}
