import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accountsKey = 'accounts_json';

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
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
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value?.toString() ?? '',
        ),
      );
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

    final accounts = <String, String>{legacyEmail: legacyPassword};
    await prefs.setString(_accountsKey, jsonEncode(accounts));
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
    if (normalized.isEmpty) return false;

    final accounts = await _readAccounts();
    if (accounts.containsKey(normalized)) {
      return false;
    }

    accounts[normalized] = password;
    await _writeAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', normalized);
    await prefs.setString('password', password);
    await prefs.setString('current_user_email', normalized);
    await prefs.setBool('is_logged_in', false);
    return true;
  }

  static Future<bool> validateCredentials(String email, String password) async {
    final normalized = normalizeEmail(email);
    final accounts = await _readAccounts();
    final savedPassword = accounts[normalized];
    return savedPassword != null && savedPassword == password;
  }

  static Future<String?> getPasswordFor(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return null;

    final accounts = await _readAccounts();
    return accounts[normalized];
  }

  static Future<bool> updatePassword(String email, String newPassword) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return false;

    final accounts = await _readAccounts();
    if (!accounts.containsKey(normalized)) return false;

    accounts[normalized] = newPassword;
    await _writeAccounts(accounts);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPassword);
    return true;
  }

  static Future<void> startSession(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) return;

    final accounts = await _readAccounts();
    final savedPassword = accounts[normalized] ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('current_user_email', normalized);
    await prefs.setString('username', normalized);
    if (savedPassword.isNotEmpty) {
      await prefs.setString('password', savedPassword);
    }
  }

  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user_email');
  }

  static Future<String> currentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return normalizeEmail(
      prefs.getString('current_user_email') ?? prefs.getString('username') ?? '',
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
    await prefs.setString('password', accounts[currentEmail] ?? '');
    return true;
  }
}
