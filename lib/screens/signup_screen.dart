import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../core/utils/validators.dart';
import '../services/otp_email_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt, size: 64, color: Color(0xFF0E7A6D)),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendSignupOtp,
                      child: Text(_sending ? 'Sending OTP...' : 'Create Account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    OtpEmailService.smtpStatusMessage(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Get.offNamed(AppRoutes.login),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendSignupOtp() async {
    if (_sending) return;

    final name = _nameCtrl.text.trim();
    final email = AuthService.normalizeEmail(_emailCtrl.text);
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill all fields.');
      return;
    }
    if (password != confirm) {
      _showMessage('Passwords do not match.');
      return;
    }
    final strengthError = validatePasswordStrength(password);
    if (strengthError != null) {
      _showMessage(strengthError);
      return;
    }

    final exists = await AuthService.accountExists(email);
    if (!mounted) return;
    if (exists) {
      _showMessage('Account already exists.');
      return;
    }

    setState(() => _sending = true);
    final result = await OtpEmailService.sendOtp(toEmail: email);
    if (!mounted) return;
    setState(() => _sending = false);

    if (!result.success) {
      _showMessage(result.message);
      return;
    }

    if (result.debugOtp != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('OTP (Dev Mode)'),
          content: Text('Your OTP is: ${result.debugOtp}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showMessage('OTP sent. Please check your email.');
    }

    if (!mounted) return;
    Get.to(
      () => SignUpOtpScreen(
        name: name,
        email: email,
        password: password,
      ),
    );
  }
}

class SignUpOtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const SignUpOtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<SignUpOtpScreen> createState() => _SignUpOtpScreenState();
}

class _SignUpOtpScreenState extends State<SignUpOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_verifying) return;
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      _showMessage('Please enter a 4-digit OTP.');
      return;
    }

    setState(() => _verifying = true);
    final ok = await OtpEmailService.verifyOtp(
      email: widget.email,
      otp: otp,
    );
    if (!mounted) return;
    setState(() => _verifying = false);

    if (!ok) {
      _showMessage('Invalid or expired OTP.');
      return;
    }

    final created = await AuthService.createAccount(
      widget.email,
      widget.password,
    );
    if (!mounted) return;
    if (!created) {
      _showMessage('Account already exists.');
      return;
    }

    await AuthService.setAccountName(widget.email, widget.name);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Verified'),
        content: const Text('Your account is ready. Please login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _resendOtp() async {
    if (_resending) return;
    setState(() => _resending = true);
    final result = await OtpEmailService.sendOtp(toEmail: widget.email);
    if (!mounted) return;
    setState(() => _resending = false);

    if (!result.success) {
      _showMessage(result.message);
      return;
    }

    if (result.debugOtp != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('OTP (Dev Mode)'),
          content: Text('Your OTP is: ${result.debugOtp}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showMessage('OTP sent again. Please check your email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: Color(0xFF0E7A6D),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'OTP',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verifyOtp,
                    child: Text(_verifying ? 'Verifying...' : 'Verify'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resending ? null : _resendOtp,
                  child: Text(_resending ? 'Resending...' : 'Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


