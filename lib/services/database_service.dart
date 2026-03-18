import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/strings.dart';

class DatabaseService {
  static Map<String, dynamic> _cache = {};
  static bool _loaded = false;
  static String? _activeUserEmail;

  static Future<void> init() async {
    await _syncActiveUserFromSession();
    await _ensureLoaded();
  }

  static Future<void> _syncActiveUserFromSession() async {
    final canAuto = await AuthService.canAutoLogin();
    if (!canAuto) return;
    final currentEmail = await AuthService.currentUserEmail();
    if (currentEmail.trim().isEmpty) return;
    _activeUserEmail = currentEmail.trim().toLowerCase();
  }

  static String _normalizeUser(String? email) {
    return (email ?? '').trim().toLowerCase();
  }

  static bool get _isGuest {
    final normalized = _normalizeUser(_activeUserEmail);
    return normalized.isEmpty;
  }

  static String get _userKey {
    if (_isGuest) return 'guest';
    final normalized = _normalizeUser(_activeUserEmail);
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  static String _keyForUser(String base) {
    if (_isGuest) return base;
    return '${base}_$_userKey';
  }

  static String _fileNameForUser(String base) {
    if (_isGuest) return base;
    final dot = base.lastIndexOf('.');
    if (dot == -1) return '${base}_$_userKey';
    return '${base.substring(0, dot)}_$_userKey${base.substring(dot)}';
  }

  static Future<void> setActiveUser(String? email) async {
    final normalized = _normalizeUser(email);
    if (normalized == _normalizeUser(_activeUserEmail) && _loaded) return;
    _activeUserEmail = normalized.isEmpty ? null : normalized;
    _loaded = false;
    _cache = {};
    await _ensureLoaded();
  }

  static Map<String, dynamic> _defaultDb() {
    return {
      'products': <Map<String, dynamic>>[],
      'categories': <Map<String, dynamic>>[],
      'suppliers': <Map<String, dynamic>>[],
      'purchases': <Map<String, dynamic>>[],
      'sales': <Map<String, dynamic>>[],
      'settings': {
        'storeName': AppStrings.defaultStoreName,
        'currency': AppStrings.defaultCurrency,
      },
    };
  }

  static Map<String, dynamic> _ensureSchema(Map<String, dynamic> db) {
    final ensured = Map<String, dynamic>.from(db);
    ensured.putIfAbsent('products', () => <Map<String, dynamic>>[]);
    ensured.putIfAbsent('categories', () => <Map<String, dynamic>>[]);
    ensured.putIfAbsent('suppliers', () => <Map<String, dynamic>>[]);
    ensured.putIfAbsent('purchases', () => <Map<String, dynamic>>[]);
    ensured.putIfAbsent('sales', () => <Map<String, dynamic>>[]);
    final settings = ensured['settings'];
    if (settings is! Map) {
      ensured['settings'] = {
        'storeName': AppStrings.defaultStoreName,
        'currency': AppStrings.defaultCurrency,
      };
    } else {
      final merged = Map<String, dynamic>.from(settings);
      merged.putIfAbsent('storeName', () => AppStrings.defaultStoreName);
      merged.putIfAbsent('currency', () => AppStrings.defaultCurrency);
      ensured['settings'] = merged;
    }
    return ensured;
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final db = await _readDb();
    _cache = _ensureSchema(db);
    _loaded = true;
  }

  static Future<Directory> _getWritableDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } on MissingPluginException {
      return Directory.systemTemp;
    } catch (_) {
      try {
        return await getTemporaryDirectory();
      } on MissingPluginException {
        return Directory.systemTemp;
      } catch (_) {
        return Directory.systemTemp;
      }
    }
  }

  static Future<File> _getDbFile() async {
    final dir = await _getWritableDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final name = _fileNameForUser(AppConstants.dbFileName);
    return File('${dir.path}/$name');
  }

  static Future<File> _getBackupFile() async {
    final dir = await _getWritableDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    final name = _fileNameForUser(AppConstants.backupFileName);
    return File('${dir.path}/$name');
  }

  static Future<Map<String, dynamic>> _readDb() async {
    if (kIsWeb) {
      return _readDbFromPrefs();
    }

    try {
      final file = await _getDbFile();
      if (!file.existsSync()) {
        final seeded = _defaultDb();
        await file.writeAsString(jsonEncode(seeded));
        return seeded;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return _defaultDb();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _defaultDb();
      return Map<String, dynamic>.from(decoded);
    } on UnsupportedError {
      return _readDbFromPrefs();
    } catch (_) {
      return _defaultDb();
    }
  }

  static Future<Map<String, dynamic>> _readDbFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser(AppConstants.dbPrefsKey));
    if (raw == null || raw.trim().isEmpty) return _defaultDb();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _defaultDb();
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return _defaultDb();
    }
  }

  static Future<void> _writeDb(Map<String, dynamic> db) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyForUser(AppConstants.dbPrefsKey),
        jsonEncode(db),
      );
      return;
    }

    try {
      final file = await _getDbFile();
      await file.writeAsString(jsonEncode(db));
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyForUser(AppConstants.dbPrefsKey),
        jsonEncode(db),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getCollection(String key) async {
    await _ensureLoaded();
    final raw = _cache[key];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> setCollection(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    await _ensureLoaded();
    _cache[key] = values;
    await _writeDb(_cache);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    await _ensureLoaded();
    final settings = _cache['settings'];
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    return {
      'storeName': AppStrings.defaultStoreName,
      'currency': AppStrings.defaultCurrency,
    };
  }

  static Future<void> updateSettings(Map<String, dynamic> values) async {
    await _ensureLoaded();
    final current = await getSettings();
    final merged = Map<String, dynamic>.from(current)..addAll(values);
    _cache['settings'] = merged;
    await _writeDb(_cache);
  }

  static Future<String> dataPath() async {
    if (kIsWeb) return 'shared_preferences';
    try {
      final file = await _getDbFile();
      return file.path;
    } on UnsupportedError {
      return 'shared_preferences';
    }
  }

  static Future<String> backupPath() async {
    if (kIsWeb) return 'shared_preferences';
    try {
      final file = await _getBackupFile();
      return file.path;
    } on UnsupportedError {
      return 'shared_preferences';
    }
  }

  static Future<String> backup() async {
    await _ensureLoaded();
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyForUser(AppConstants.backupPrefsKey),
        jsonEncode(_cache),
      );
      return 'shared_preferences';
    }

    try {
      final backupFile = await _getBackupFile();
      await backupFile.writeAsString(jsonEncode(_cache));
      return backupFile.path;
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyForUser(AppConstants.backupPrefsKey),
        jsonEncode(_cache),
      );
      return 'shared_preferences';
    }
  }

  static Future<bool> restore() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyForUser(AppConstants.backupPrefsKey));
      if (raw == null || raw.trim().isEmpty) return false;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return false;
        _cache = _ensureSchema(Map<String, dynamic>.from(decoded));
        await _writeDb(_cache);
        return true;
      } catch (_) {
        return false;
      }
    }

    try {
      final backupFile = await _getBackupFile();
      if (!backupFile.existsSync()) return false;
      final raw = await backupFile.readAsString();
      if (raw.trim().isEmpty) return false;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      _cache = _ensureSchema(Map<String, dynamic>.from(decoded));
      await _writeDb(_cache);
      return true;
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyForUser(AppConstants.backupPrefsKey));
      if (raw == null || raw.trim().isEmpty) return false;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return false;
        _cache = _ensureSchema(Map<String, dynamic>.from(decoded));
        await _writeDb(_cache);
        return true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<void> reset() async {
    _cache = _defaultDb();
    _loaded = true;
    await _writeDb(_cache);
  }
}
