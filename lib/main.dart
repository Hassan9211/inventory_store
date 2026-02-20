import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_store/widgets/app_router_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool('is_dark_theme') ?? false;
  final languageCode = prefs.getString('language_code') ?? 'en';

  runApp(
    AppRouterWidget(
      initialThemeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      initialLanguageCode: languageCode,
    ),
  );
}
