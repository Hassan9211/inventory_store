import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/fruit.dart';

class StorageService {
  // MAIN DATA FILE
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/fruits.json');
  }

  // BACKUP FILE
  static Future<File> _getBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/backup.json');
  }

  // SAVE DATA
  static Future<void> saveFruits(List<Fruit> fruits) async {
    final file = await _getFile();
    final data = fruits.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  // LOAD DATA
  static Future<List<Fruit>> loadFruits() async {
    final file = await _getFile();
    if (!file.existsSync()) return [];

    final data = jsonDecode(await file.readAsString());
    return data.map<Fruit>((e) => Fruit.fromJson(e)).toList();
  }

  // BACKUP
  static Future<void> backup(List<Fruit> fruits) async {
    final file = await _getBackupFile();
    final data = fruits.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  // RESTORE  ✅ (THIS WAS MISSING)
  static Future<List<Fruit>> restore() async {
    final file = await _getBackupFile();
    if (!file.existsSync()) return [];

    final data = jsonDecode(await file.readAsString());
    return data.map<Fruit>((e) => Fruit.fromJson(e)).toList();
  }
}
