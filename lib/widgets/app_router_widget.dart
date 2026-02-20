import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory_store/models/cart_item.dart';
import 'package:inventory_store/screens/bill_screen.dart';
import 'package:inventory_store/screens/home_screen.dart';
import 'package:inventory_store/screens/login_screen.dart';
import 'package:inventory_store/screens/settings_screen.dart';
import 'package:inventory_store/screens/signup_screen.dart';
import 'package:inventory_store/screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const signup = '/signup';
  static const login = '/login';
  static const home = '/home';
  static const bill = '/bill';
  static const settings = '/settings';
}

class AppRouterWidget extends StatelessWidget {
  final ThemeMode initialThemeMode;
  final String initialLanguageCode;

  const AppRouterWidget({
    super.key,
    required this.initialThemeMode,
    required this.initialLanguageCode,
  });

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A4D),
      brightness: Brightness.light,
      surface: const Color(0xFFF7F7F4),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A4D),
      brightness: Brightness.dark,
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      themeMode: initialThemeMode,
      locale: Locale(initialLanguageCode),
      theme: ThemeData(
        colorScheme: lightScheme,
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F7F4),
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1B1B),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1B1B1B)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE9E9E5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F3F0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E3DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E3DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: lightScheme.primary),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(name: AppRoutes.signup, page: () => const SignUpPage()),
        GetPage(
          name: AppRoutes.login,
          page: () {
            final args = Get.arguments as Map<String, dynamic>?;
            final skipAutoLogin = args?['skipAutoLogin'] == true;
            return LoginScreen(skipAutoLogin: skipAutoLogin);
          },
        ),
        GetPage(name: AppRoutes.home, page: () => HomeScreen()),
        GetPage(
          name: AppRoutes.bill,
          page: () {
            final args = Get.arguments;
            final cart = args is List
                ? args.whereType<CartItem>().toList()
                : <CartItem>[];
            return BillScreen(cart: cart);
          },
        ),
        GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
      ],
    );
  }
}
