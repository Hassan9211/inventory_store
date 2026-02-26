import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OtpEmailSendResult {
  final bool success;
  final String message;

  const OtpEmailSendResult({required this.success, required this.message});
}

class OtpEmailService {
  static const String _smtpHost = String.fromEnvironment('OTP_SMTP_HOST');
  static const String _smtpPortRaw = String.fromEnvironment(
    'OTP_SMTP_PORT',
    defaultValue: '587',
  );
  static const String _smtpUsername = String.fromEnvironment(
    'OTP_SMTP_USERNAME',
  );
  static const String _smtpPassword = String.fromEnvironment(
    'OTP_SMTP_PASSWORD',
  );
  static const String _fromEmail = String.fromEnvironment('OTP_FROM_EMAIL');
  static const String _fromName = String.fromEnvironment(
    'OTP_FROM_NAME',
    defaultValue: 'Inventory Store',
  );
  static const String _useSslRaw = String.fromEnvironment(
    'OTP_SMTP_SSL',
    defaultValue: 'false',
  );

  static bool get _hasRequiredConfig {
    return _smtpHost.isNotEmpty &&
        _smtpUsername.isNotEmpty &&
        _smtpPassword.isNotEmpty &&
        _fromEmail.isNotEmpty;
  }

  static String get _smtpPasswordValue {
    final raw = _smtpPassword.trim();
    if (_smtpHost.trim().toLowerCase() == 'smtp.gmail.com') {
      // Gmail app passwords are often copied with spaces every 4 chars.
      return raw.replaceAll(' ', '');
    }
    return raw;
  }

  static String get _smtpHostValue => _smtpHost.trim();
  static String get _smtpUserValue => _smtpUsername.trim();
  static String get _fromEmailValue => _fromEmail.trim();

  static int get _smtpPort {
    return int.tryParse(_smtpPortRaw) ?? 587;
  }

  static bool get _useSsl {
    final value = _useSslRaw.trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static bool get _isGmailHost =>
      _smtpHostValue.toLowerCase() == 'smtp.gmail.com';

  static SmtpServer _buildServer({required int port, required bool ssl}) {
    return SmtpServer(
      _smtpHostValue,
      port: port,
      username: _smtpUserValue,
      password: _smtpPasswordValue,
      ssl: ssl,
      allowInsecure: false,
    );
  }

  static String _formatMailerException(MailerException e) {
    final problemText = e.problems
        .map((p) => '${p.code}: ${p.msg}')
        .where((s) => s.trim().isNotEmpty)
        .join(' | ');
    if (problemText.isNotEmpty) return problemText;
    final text = e.toString().trim();
    return text.isEmpty ? 'SMTP authentication failed.' : text;
  }

  static Future<String?> _trySend({
    required Message message,
    required SmtpServer server,
    required String label,
  }) async {
    try {
      await send(message, server);
      return null;
    } on MailerException catch (e) {
      return '$label -> ${_formatMailerException(e)}';
    } on SocketException catch (e) {
      return '$label -> Network error: ${e.message}';
    } on HandshakeException catch (e) {
      return '$label -> TLS/SSL error: ${e.message}';
    } catch (e) {
      return '$label -> ${e.toString()}';
    }
  }

  static Future<OtpEmailSendResult> sendOtp({
    required String toEmail,
    required String otp,
  }) async {
    if (!_hasRequiredConfig) {
      return const OtpEmailSendResult(
        success: false,
        message:
            'OTP email is not configured. Add SMTP dart-defines before build.',
      );
    }

    final message = Message()
      ..from = Address(_fromEmailValue, _fromName)
      ..recipients.add(toEmail)
      ..subject = 'Inventory Store Password Reset OTP'
      ..text =
          'Your OTP for password reset is: $otp\n\n'
          'This OTP is valid for one-time verification.\n'
          'If you did not request this, ignore this email.';

    final attempts = <({SmtpServer server, String label})>[];
    attempts.add((
      server: _buildServer(port: _smtpPort, ssl: _useSsl),
      label: '${_smtpHostValue}:${_smtpPort} ssl=$_useSsl',
    ));

    if (_isGmailHost) {
      if (!(_smtpPort == 465 && _useSsl)) {
        attempts.add((
          server: _buildServer(port: 465, ssl: true),
          label: 'smtp.gmail.com:465 ssl=true',
        ));
      }
      if (!(_smtpPort == 587 && !_useSsl)) {
        attempts.add((
          server: _buildServer(port: 587, ssl: false),
          label: 'smtp.gmail.com:587 ssl=false',
        ));
      }
    }

    final errors = <String>[];
    for (final attempt in attempts) {
      final error = await _trySend(
        message: message,
        server: attempt.server,
        label: attempt.label,
      );
      if (error == null) {
        return const OtpEmailSendResult(
          success: true,
          message: 'OTP sent successfully.',
        );
      }
      errors.add(error);
    }

    return OtpEmailSendResult(success: false, message: errors.join('\n'));
  }
}
