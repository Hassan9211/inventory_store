import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpSendResult {
  final bool success;
  final String message;
  final String? debugOtp;

  const OtpSendResult({
    required this.success,
    required this.message,
    this.debugOtp,
  });
}

class OtpEmailService {
  static const String _otpKeyPrefix = 'otp_code_';
  static const int _ttlMinutes = 10;

  static const String _smtpHost = String.fromEnvironment('OTP_SMTP_HOST');
  static const String _smtpPortRaw = String.fromEnvironment(
    'OTP_SMTP_PORT',
    defaultValue: '587',
  );
  static const String _smtpUsername = String.fromEnvironment('OTP_SMTP_USERNAME');
  static const String _smtpPassword = String.fromEnvironment('OTP_SMTP_PASSWORD');
  static const String _fromEmail = String.fromEnvironment('OTP_FROM_EMAIL');
  static const String _fromName = String.fromEnvironment(
    'OTP_FROM_NAME',
    defaultValue: 'Inventory Store',
  );
  static const String _useSslRaw = String.fromEnvironment(
    'OTP_SMTP_SSL',
    defaultValue: 'false',
  );
  static const bool _devOtp = bool.fromEnvironment('OTP_DEV_OTP', defaultValue: false);
  static const bool _showDebugOtp =
      bool.fromEnvironment('OTP_SHOW_DEBUG_OTP', defaultValue: false);

  static bool get _hasSmtpConfig {
    return _smtpHost.trim().isNotEmpty &&
        _smtpUsername.trim().isNotEmpty &&
        _smtpPassword.trim().isNotEmpty &&
        _fromEmail.trim().isNotEmpty;
  }

  static bool get isSmtpConfigured => _hasSmtpConfig && !kIsWeb;

  static String smtpStatusMessage() {
    if (kIsWeb) {
      return 'OTP: SMTP disabled on web builds.';
    }
    if (_devOtp) {
      return _showDebugOtp
          ? 'OTP: Dev mode (debug OTP visible).'
          : 'OTP: Dev mode (debug OTP hidden).';
    }
    if (!_hasSmtpConfig) {
      final missing = <String>[];
      if (_smtpHost.trim().isEmpty) missing.add('OTP_SMTP_HOST');
      if (_smtpUsername.trim().isEmpty) missing.add('OTP_SMTP_USERNAME');
      if (_smtpPassword.trim().isEmpty) missing.add('OTP_SMTP_PASSWORD');
      if (_fromEmail.trim().isEmpty) missing.add('OTP_FROM_EMAIL');
      if (missing.isEmpty) {
        return 'OTP: SMTP not configured. Set OTP_SMTP_* values.';
      }
      return 'OTP: Missing ${missing.join(', ')}';
    }
    return 'OTP: SMTP configured.';
  }

  static int get _smtpPort => int.tryParse(_smtpPortRaw) ?? 587;

  static bool get _useSsl {
    final value = _useSslRaw.trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static final Random _secureRandom = Random.secure();

  static String _generateOtp() {
    return (1000 + _secureRandom.nextInt(9000)).toString();
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(12, (_) => _secureRandom.nextInt(256));
    return base64UrlEncode(bytes);
  }


  static String _hashOtp(String otp, String salt) {
    return sha256.convert(utf8.encode('$salt:$otp')).toString();
  }

  static String _keyForEmail(String email) {
    final normalized = _normalizeEmail(email);
    return '$_otpKeyPrefix$normalized';
  }

  static String get _smtpPasswordValue {
    final raw = _smtpPassword.trim();
    if (_smtpHost.trim().toLowerCase() == 'smtp.gmail.com') {
      return raw.replaceAll(' ', '');
    }
    return raw;
  }

  static String _formatMailerException(MailerException e) {
    final problemText = e.problems
        .map((p) => '${p.code}: ${p.msg}')
        .where((s) => s.trim().isNotEmpty)
        .join(' | ');
    if (problemText.isNotEmpty) return problemText;
    final text = e.toString().trim();
    return text.isEmpty ? 'SMTP error.' : text;
  }

  static Future<void> _storeOtp(String email, String otp) async {
    final salt = _generateSalt();
    final hash = _hashOtp(otp, salt);
    final expiresAt = DateTime.now()
        .add(const Duration(minutes: _ttlMinutes))
        .toIso8601String();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyForEmail(email),
      jsonEncode({
        'salt': salt,
        'hash': hash,
        'expiresAt': expiresAt,
      }),
    );
  }

  static Future<OtpSendResult> sendOtp({required String toEmail}) async {
    final normalized = _normalizeEmail(toEmail);
    if (normalized.isEmpty) {
      return const OtpSendResult(
        success: false,
        message: 'Email is required to send OTP.',
      );
    }

    if (_devOtp) {
      final otp = _generateOtp();
      await _storeOtp(normalized, otp);
      if (_showDebugOtp) {
        return OtpSendResult(
          success: true,
          message: 'OTP generated in dev mode.',
          debugOtp: otp,
        );
      }
      return const OtpSendResult(
        success: false,
        message: 'OTP dev mode is enabled but debug OTP is hidden.',
      );
    }

    if (!_hasSmtpConfig || kIsWeb) {
      return const OtpSendResult(
        success: false,
        message: 'SMTP not configured. Please set OTP_SMTP_* values.',
      );
    }

    final otp = _generateOtp();
    await _storeOtp(normalized, otp);

    final message = Message()
      ..from = Address(_fromEmail.trim(), _fromName)
      ..recipients.add(normalized)
      ..subject = 'Password Reset OTP'
      ..text =
          'Your OTP is: $otp\n\nThis OTP is valid for $_ttlMinutes minutes.';

    final server = SmtpServer(
      _smtpHost.trim(),
      port: _smtpPort,
      username: _smtpUsername.trim(),
      password: _smtpPasswordValue,
      ssl: _useSsl,
    );

    try {
      await send(message, server);
      return const OtpSendResult(
        success: true,
        message: 'OTP sent successfully. Please check your email.',
      );
    } on MailerException catch (e) {
      return OtpSendResult(
        success: false,
        message: 'OTP email failed: ${_formatMailerException(e)}',
      );
    } catch (e) {
      return OtpSendResult(
        success: false,
        message: 'OTP email failed: ${e.toString()}',
      );
    }
  }

  static Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || otp.trim().isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForEmail(normalized));
    if (raw == null || raw.trim().isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final salt = decoded['salt']?.toString() ?? '';
      final hash = decoded['hash']?.toString() ?? '';
      final expiresAtRaw = decoded['expiresAt']?.toString() ?? '';
      if (salt.isEmpty || hash.isEmpty || expiresAtRaw.isEmpty) return false;

      final expiresAt = DateTime.tryParse(expiresAtRaw);
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        await prefs.remove(_keyForEmail(normalized));
        return false;
      }

      final candidate = _hashOtp(otp.trim(), salt);
      final ok = candidate == hash;
      if (ok) {
        await prefs.remove(_keyForEmail(normalized));
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}
