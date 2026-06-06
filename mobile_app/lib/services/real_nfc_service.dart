// ignore_for_file: implementation_imports, invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef.dart';

import 'nfc_service.dart';

class RealNfcService implements NfcService {
  @override
  Future<String?> scanToken() async {
    // The implementation below starts an NFC session and reads the first record
    // found on a tag. In a real environment, you may need to adjust how the
    // token is encoded and how you parse it.
    final availability = await _checkAvailability();
    if (availability != NfcAvailability.enabled) {
      // NFC not available on this device or target.
      return null;
    }

    final completer = Completer<String?>();

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          // Try reading NDEF records (common for NFC tokens).
          final ndef = NdefAndroid.from(tag);
          if (ndef != null) {
            final ndefMessage = ndef.cachedNdefMessage;
            if (ndefMessage != null && ndefMessage.records.isNotEmpty) {
              final payload = ndefMessage.records.first.payload;
              final token = _decodePayload(payload);
              if (!completer.isCompleted) {
                completer.complete(token);
              }
              return;
            }
          }

          // Fallback: use raw tag ID as token.
          final data = tag.data;
          if (data is Map && data.containsKey('id')) {
            final id = data['id'];
            if (id is List<int>) {
              final token = id.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
              if (!completer.isCompleted) {
                completer.complete(token);
              }
              return;
            }
          }
        } catch (_) {
          // ignore errors; return null
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );

    return completer.future;
  }

  Future<NfcAvailability> _checkAvailability() async {
    try {
      return await NfcManager.instance.checkAvailability();
    } on MissingPluginException {
      return NfcAvailability.unsupported;
    } on PlatformException {
      return NfcAvailability.unsupported;
    } on UnsupportedError {
      return NfcAvailability.unsupported;
    }
  }

  String _decodePayload(Uint8List payload) {
    if (payload.isEmpty) {
      return '';
    }

    final decodedText = _tryDecodeNdefTextPayload(payload);
    if (decodedText != null && decodedText.trim().isNotEmpty) {
      return decodedText.trim();
    }

    return utf8.decode(payload, allowMalformed: true).trim();
  }

  String? _tryDecodeNdefTextPayload(Uint8List payload) {
    if (payload.length < 3) {
      return null;
    }

    final statusByte = payload.first;
    final languageCodeLength = statusByte & 0x3F;
    final usesUtf16 = (statusByte & 0x80) != 0;
    final textStartIndex = 1 + languageCodeLength;

    if (textStartIndex >= payload.length) {
      return null;
    }

    final textBytes = payload.sublist(textStartIndex);
    try {
      if (usesUtf16) {
        return _decodeUtf16(textBytes);
      }

      return utf8.decode(textBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  String _decodeUtf16(Uint8List bytes) {
    if (bytes.isEmpty) {
      return '';
    }

    var startIndex = 0;
    var littleEndian = false;

    if (bytes.length >= 2) {
      final bom0 = bytes[0];
      final bom1 = bytes[1];
      if (bom0 == 0xFF && bom1 == 0xFE) {
        littleEndian = true;
        startIndex = 2;
      } else if (bom0 == 0xFE && bom1 == 0xFF) {
        littleEndian = false;
        startIndex = 2;
      }
    }

    final codeUnits = <int>[];
    for (var i = startIndex; i + 1 < bytes.length; i += 2) {
      final first = bytes[i];
      final second = bytes[i + 1];
      codeUnits.add(littleEndian ? first | (second << 8) : (first << 8) | second);
    }

    return String.fromCharCodes(codeUnits);
  }
}
