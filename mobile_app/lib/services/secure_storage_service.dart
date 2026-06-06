import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class SecureStorageService {
  static const _keyJwt = 'jwt_token';
  static const _keyUserJson = 'user_json';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveJwt(String jwt) async {
    try {
      await _storage.write(key: _keyJwt, value: jwt);
    } on MissingPluginException {
      // Emulator fallback: plugin may be intentionally skipped.
    }
  }

  Future<String?> readJwt() async {
    try {
      return _storage.read(key: _keyJwt);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> deleteJwt() async {
    try {
      await _storage.delete(key: _keyJwt);
    } on MissingPluginException {
      // Emulator fallback: plugin may be intentionally skipped.
    }
  }

  Future<void> saveUserJson(String userJson) async {
    try {
      await _storage.write(key: _keyUserJson, value: userJson);
    } on MissingPluginException {
      // Emulator fallback: plugin may be intentionally skipped.
    }
  }

  Future<String?> readUserJson() async {
    try {
      return _storage.read(key: _keyUserJson);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> deleteUserJson() async {
    try {
      await _storage.delete(key: _keyUserJson);
    } on MissingPluginException {
      // Emulator fallback: plugin may be intentionally skipped.
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } on MissingPluginException {
      // Emulator fallback: plugin may be intentionally skipped.
    }
  }
}
