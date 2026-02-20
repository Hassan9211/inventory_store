import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/fruit.dart';

class StorageService {
  static Directory _platformFallbackDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData/inventory_store');
      }
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && userProfile.isNotEmpty) {
        return Directory('$userProfile/Documents/inventory_store');
      }
    }

    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory('$home/.local/share/inventory_store');
      }
    }

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory('$home/Library/Application Support/inventory_store');
      }
    }

    return Directory('${Directory.systemTemp.path}/inventory_store');
  }

  static Future<Directory> _getWritableDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } on MissingPluginException {
      return _platformFallbackDirectory();
    } catch (_) {
      try {
        return await getApplicationSupportDirectory();
      } on MissingPluginException {
        return _platformFallbackDirectory();
      } catch (_) {
        try {
          return await getTemporaryDirectory();
        } on MissingPluginException {
          return _platformFallbackDirectory();
        } catch (_) {
          return _platformFallbackDirectory();
        }
      }
    }
  }

  static Future<File> _ensureJsonFile(String fileName) async {
    final dir = await _getWritableDirectory();
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}/$fileName');
    if (!file.existsSync()) {
      await file.writeAsString('[]');
    }

    return file;
  }

  static String _sanitizeUserKey(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  static Future<String> _getCurrentUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    final email =
        prefs.getString('current_user_email') ?? prefs.getString('username') ?? '';
    return _sanitizeUserKey(email);
  }

  static Future<String> _fruitsPrefsKey() async {
    final userKey = await _getCurrentUserKey();
    return userKey.isEmpty ? 'fruits_json' : 'fruits_json_$userKey';
  }

  static Future<String> _backupPrefsKey() async {
    final userKey = await _getCurrentUserKey();
    return userKey.isEmpty ? 'backup_json' : 'backup_json_$userKey';
  }

  static bool _isEmptyJsonArray(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty || trimmed == '[]';
  }

  static Future<void> _migrateLegacyFileIfNeeded({
    required File scopedFile,
    required String legacyFileName,
  }) async {
    final scopedRaw = await scopedFile.readAsString();
    if (!_isEmptyJsonArray(scopedRaw)) return;

    final dir = await _getWritableDirectory();
    final legacyFile = File('${dir.path}/$legacyFileName');
    if (!legacyFile.existsSync()) return;

    final legacyRaw = await legacyFile.readAsString();
    if (_isEmptyJsonArray(legacyRaw)) return;
    await scopedFile.writeAsString(legacyRaw);
  }

  // MAIN DATA FILE
  static Future<File> _getFile() async {
    final userKey = await _getCurrentUserKey();
    if (userKey.isEmpty) return _ensureJsonFile('fruits.json');

    final scopedFile = await _ensureJsonFile('fruits_$userKey.json');
    await _migrateLegacyFileIfNeeded(
      scopedFile: scopedFile,
      legacyFileName: 'fruits.json',
    );
    return scopedFile;
  }

  // BACKUP FILE
  static Future<File> _getBackupFile() async {
    final userKey = await _getCurrentUserKey();
    if (userKey.isEmpty) return _ensureJsonFile('backup.json');

    final scopedFile = await _ensureJsonFile('backup_$userKey.json');
    await _migrateLegacyFileIfNeeded(
      scopedFile: scopedFile,
      legacyFileName: 'backup.json',
    );
    return scopedFile;
  }

  // SAVE DATA
  static Future<void> saveFruits(List<Fruit> fruits) async {
    final data = fruits.map((e) => e.toJson()).toList();
    final json = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _fruitsPrefsKey(), json);
      return;
    }

    try {
      final file = await _getFile();
      await file.writeAsString(json);
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _fruitsPrefsKey(), json);
    }
  }

  // LOAD DATA
  static Future<List<Fruit>> loadFruits() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(await _fruitsPrefsKey()) ?? '[]';
        final data = jsonDecode(raw);
        if (data is! List) return [];
        return data
            .whereType<Map>()
            .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final file = await _getFile();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];

      final data = jsonDecode(raw);
      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(await _fruitsPrefsKey()) ?? '[]';
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // BACKUP
  static Future<void> backup(List<Fruit> fruits) async {
    final data = fruits.map((e) => e.toJson()).toList();
    final json = jsonEncode(data);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _backupPrefsKey(), json);
      return;
    }

    try {
      final file = await _getBackupFile();
      await file.writeAsString(json);
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(await _backupPrefsKey(), json);
    }
  }

  static Future<String> backupPath() async {
    if (kIsWeb) return 'web_shared_preferences';

    try {
      final file = await _getBackupFile();
      return file.path;
    } on UnsupportedError {
      return 'shared_preferences_fallback';
    }
  }

  // RESTORE
  static Future<List<Fruit>> restore() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(await _backupPrefsKey()) ?? '[]';
        final data = jsonDecode(raw);
        if (data is! List) return [];
        return data
            .whereType<Map>()
            .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      final file = await _getBackupFile();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];

      final data = jsonDecode(raw);
      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on UnsupportedError {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(await _backupPrefsKey()) ?? '[]';
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => Fruit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
