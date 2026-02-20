// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inventory_store/services/auth_service.dart';
import 'package:inventory_store/widgets/app_router_widget.dart';

class LoginScreen extends StatefulWidget {
  final bool skipAutoLogin; // to prevent auto-login after signup

  const LoginScreen({super.key, this.skipAutoLogin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    if (!widget.skipAutoLogin) _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final shouldAutoLogin = await AuthService.canAutoLogin();
    if (shouldAutoLogin) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _openForgotPasswordFlow() {
    Get.to(() => ForgotPasswordEmailScreen(initialEmail: userCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;
    final formWidth = isDesktop
        ? 520.0
        : isTablet
            ? 420.0
            : (width * 0.92).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF7F7F4), Color(0xFFEAF4EC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFBEE3CB).withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Container(
                  width: formWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F7A4D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Inventory Store",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Sign in to manage inventory and billing.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF6B6B6B)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: userCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _openForgotPasswordFlow,
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (userCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter Email & Password"),
                                ),
                              );
                              return;
                            }

                            final enteredUser =
                                AuthService.normalizeEmail(userCtrl.text);
                            final isValid = await AuthService.validateCredentials(
                              enteredUser,
                              passwordCtrl.text,
                            );

                            if (isValid) {
                              await AuthService.startSession(enteredUser);
                              Get.offAllNamed(AppRoutes.home);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Wrong Email or password"),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          Get.offNamed(AppRoutes.signup);
                        },
                        child: const Text("Don't have an account? Sign Up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordEmailScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordEmailScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  late final TextEditingController emailCtrl;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = AuthService.normalizeEmail(emailCtrl.text);
    if (email.isEmpty) {
      Get.snackbar(
        "Missing Email",
        "Please enter your email.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final exists = await AuthService.accountExists(email);
    if (!exists) {
      Get.snackbar(
        "Not Found",
        "No account found for this email.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final otp = (1000 + Random().nextInt(9000)).toString();

    // Demo app: show OTP in-app instead of sending email service.
    Get.snackbar(
      "OTP Sent",
      "Your 4-digit OTP is $otp",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );

    Get.to(
      () => ForgotPasswordOtpScreen(
        email: email,
        expectedOtp: otp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: Color(0xFF1F7A4D),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Enter your email to reset your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    child: const Text("Send OTP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  final String expectedOtp;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
    required this.expectedOtp,
  });

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final otpCtrl = TextEditingController();

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = otpCtrl.text.trim();
    if (enteredOtp.length != 4) {
      Get.snackbar(
        "Invalid OTP",
        "Please enter a 4-digit OTP.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (enteredOtp != widget.expectedOtp) {
      Get.snackbar(
        "Wrong OTP",
        "The OTP you entered is incorrect.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updated = await AuthService.updatePassword(widget.email, enteredOtp);
    if (!updated) {
      Get.snackbar(
        "Failed",
        "Could not update password.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await AuthService.endSession();
    Get.offAll(
      () => PasswordResetSuccessScreen(
        email: widget.email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: Color(0xFF1F7A4D),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Enter 4-digit OTP",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: "OTP",
                    prefixIcon: Icon(Icons.password),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text("Verify OTP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  final String email;

  const PasswordResetSuccessScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Color(0x1F1F7A4D),
                  child: Icon(Icons.check, size: 54, color: Color(0xFF1F7A4D)),
                ),
                const SizedBox(height: 18),
                const Text(
                  "You have successfully update your password",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  "Email: $email\nUse your OTP as the new password.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.offAllNamed(
                        AppRoutes.login,
                        arguments: {'skipAutoLogin': true},
                      );
                    },
                    child: const Text("Back to Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
