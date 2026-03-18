import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/otp_email_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String _email = '';
  bool _loading = true;
  bool _sending = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService.currentUserEmail();
    if (!mounted) return;
    if (email.trim().isEmpty) {
      _showMessage('Please login again.');
      Get.back();
      return;
    }
    setState(() {
      _email = email.trim();
      _loading = false;
    });
  }

  Future<void> _sendOtp() async {
    if (_sending) return;
    final currentPassword = _currentCtrl.text.trim();
    final newPassword = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      _showMessage('Please fill all fields.');
      return;
    }
    final strengthError = validatePasswordStrength(newPassword);
    if (strengthError != null) {
      _showMessage(strengthError);
      return;
    }
    if (newPassword != confirm) {
      _showMessage('Passwords do not match.');
      return;
    }

    final valid = await AuthService.validateCredentials(_email, currentPassword);
    if (!valid) {
      _showMessage('Current password is incorrect.');
      return;
    }

    setState(() => _sending = true);
    final result = await OtpEmailService.sendOtp(toEmail: _email);
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
      () => ChangePasswordOtpScreen(
        email: _email,
        newPassword: newPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.password_outlined,
                        size: 64,
                        color: Color(0xFF0E7A6D),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF6B6B6B)),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _currentCtrl,
                        obscureText: _hideCurrent,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hideCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _hideCurrent = !_hideCurrent);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newCtrl,
                        obscureText: _hideNew,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hideNew ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _hideNew = !_hideNew);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: _hideConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hideConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _hideConfirm = !_hideConfirm);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendOtp,
                          child: Text(_sending ? 'Sending OTP...' : 'Send OTP'),
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

class ChangePasswordOtpScreen extends StatefulWidget {
  final String email;
  final String newPassword;

  const ChangePasswordOtpScreen({
    super.key,
    required this.email,
    required this.newPassword,
  });

  @override
  State<ChangePasswordOtpScreen> createState() =>
      _ChangePasswordOtpScreenState();
}

class _ChangePasswordOtpScreenState extends State<ChangePasswordOtpScreen> {
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

    final updated = await AuthService.updatePassword(
      widget.email,
      widget.newPassword,
    );
    if (!updated) {
      _showMessage('Could not update password.');
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Updated'),
        content: const Text('Password updated. Please login again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await AuthService.endSession();
    await DatabaseService.setActiveUser(null);
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

