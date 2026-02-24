import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accountsKey = 'accounts_json';
  static const String _credentialPrefix = 'v1:';
  static const int _hashRounds = 12000;
  static final Random _secureRandom = Random.secure();

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    var digest = sha256.convert(utf8.encode('$salt:$password'));
    for (var i = 0; i < _hashRounds; i++) {
      digest = sha256.convert([
        ...digest.bytes,
        ...passwordBytes,
        ...saltBytes,
      ]);
    }

    return base64UrlEncode(digest.bytes);
  }

  static bool _isHashedCredential(String value) {
    return value.startsWith(_credentialPrefix);
  }

  static String _encodeCredential(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    return '$_credentialPrefix$salt:$hash';
  }

  static bool _verifyCredential(String storedCredential, String password) {
    if (storedCredential.isEmpty) return false;

    if (!_isHashedCredential(storedCredential)) {
      // Legacy plain-text value support for migration.
      return storedCredential == password;
    }

    final parts = storedCredential.split(':');
    if (parts.length != 3) return false;

    final salt = parts[1];
    final expectedHash = parts[2];
    final actualHash = _hashPassword(password, salt);
    return actualHash == expectedHash;
  }

  static Future<Map<String, String>> _upgradeAccountsIfNeeded(
    Map<String, String> accounts,
  ) async {
    var changed = false;
    final upgraded = <String, String>{};

    for (final entry in accounts.entries) {
      final normalizedEmail = normalizeEmail(entry.key);
      final credential = entry.value;

      if (normalizedEmail.isEmpty || credential.isEmpty) {
        changed = true;
        continue;
      }

      if (normalizedEmail != entry.key) {
        changed = true;
      }

      if (_isHashedCredential(credential)) {
        upgraded[normalizedEmail] = credential;
      } else {
        upgraded[normalizedEmail] = _encodeCredential(credential);
        changed = true;
      }
    }

    if (changed) {
      await _writeAccounts(upgraded);
    }
    return upgraded;
  }

  static Future<Map<String, String>> _readAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);

    if (raw == null || raw.trim().isEmpty) {
      return _migrateLegacyAccountIfNeeded(prefs);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final accounts = decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
      return _upgradeAccountsIfNeeded(accounts);
    } catch (_) {
      return {};
    }
  }

  static Future<Map<String, String>> _migrateLegacyAccountIfNeeded(
    SharedPreferences prefs,
  ) async {
    final legacyEmail = normalizeEmail(prefs.getString('username') ?? '');
    final legacyPassword =
        prefs.getString('password') ?? prefs.getString('pin') ?? '';

    if (legacyEmail.isEmpty || legacyPassword.isEmpty) {
      return {};
    }

    final accounts = <String, String>{
      legacyEmail: _encodeCredential(legacyPassword),
    };
    await prefs.setString(_accountsKey, jsonEncode(accounts));
    await prefs.remove('password');
    await prefs.remove('pin');
    return accounts;
  }

  static Future<void> _writeAccounts(Map<String, String> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static Future<bool> hasAnyAccount() async {
    final accounts = await _readAccounts();
    return accounts.isNotEmpty;
  }

  static Future<bool> accountExists(String email) async {
    final normalized = normalizeEmail(email);
    final accounts = await _readAccounts();
    return accounts.containsKey(normalized);
  }

  static Future<bool> createAccount(String email, String password) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty) return false;

    final accounts = await _readAccounts();
    if (accounts.containsKey(normalized)) {
      return false;
    }

    accounts[normalized] = _encodeCredential(password);
    await _writeAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', normalized);
    await prefs.setString('current_user_email', normalized);
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('password');
    await prefs.remove('pin');
    return true;
  }

  static Future<bool> validateCredentials(String email, String password) async {
    final normalized = normalizeEmail(email);
    final accounts = await _readAccounts();
    final savedCredential = accounts[normalized];
    if (savedCredential == null) return false;

    final isValid = _verifyCredential(savedCredential, password);
    if (!isValid) return false;

    if (!_isHashedCredential(savedCredential)) {
      accounts[normalized] = _encodeCredential(password);
      await _writeAccounts(accounts);
    }
    return true;
  }

  static Future<bool> updatePassword(String email, String newPassword) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty || newPassword.isEmpty) return false;

    final accounts = await _readAccounts();
    if (!accounts.containsKey(normalized)) return false;

    accounts[normalized] = _encodeCredential(newPassword);
    await _writeAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    await prefs.remove('pin');
    return true;
  }

  static Future<void> startSession(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('current_user_email', normalized);
    await prefs.setString('username', normalized);
    await prefs.remove('password');
    await prefs.remove('pin');
  }

  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user_email');
  }

  static Future<String> currentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return normalizeEmail(
      prefs.getString('current_user_email') ??
          prefs.getString('username') ??
          '',
    );
  }

  static Future<bool> canAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) return false;

    final currentEmail = await currentUserEmail();
    if (currentEmail.isEmpty) return false;

    final accounts = await _readAccounts();
    if (!accounts.containsKey(currentEmail)) return false;

    await prefs.setString('current_user_email', currentEmail);
    await prefs.setString('username', currentEmail);
    await prefs.remove('password');
    await prefs.remove('pin');
    return true;
  }
}
