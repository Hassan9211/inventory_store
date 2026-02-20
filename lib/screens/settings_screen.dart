import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventory_store/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String languageCode = 'en';

  @override
  void initState() {
    super.initState();
    isDarkMode = Get.isDarkMode;
    languageCode = Get.locale?.languageCode ?? 'en';
  }

  String _text(String en, String ur) {
    return languageCode == 'ur' ? ur : en;
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() {
      isDarkMode = value;
    });
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', value);
  }

  Future<void> _changeLanguage(String? value) async {
    if (value == null) return;

    setState(() {
      languageCode = value;
    });
    Get.updateLocale(Locale(value));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', value);
  }

  Future<void> _logout() async {
    await AuthService.endSession();
    Get.offAllNamed(
      '/login',
      arguments: {'skipAutoLogin': true},
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            _text('Change Password', 'پاس ورڈ تبدیل کریں'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _text('Current Password', 'موجودہ پاس ورڈ'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _text('New Password', 'نیا پاس ورڈ'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _text('Confirm Password', 'پاس ورڈ کی تصدیق'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(_text('Cancel', 'منسوخ')),
            ),
            TextButton(
              onPressed: () async {
                final currentEmail = await AuthService.currentUserEmail();
                final savedPassword = await AuthService.getPasswordFor(
                      currentEmail,
                    ) ??
                    '';

                if (currentCtrl.text != savedPassword) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _text('Current password is incorrect', 'موجودہ پاس ورڈ غلط ہے'),
                        ),
                      ),
                    );
                  }
                  return;
                }

                if (newCtrl.text.length < 4) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _text('New password must be at least 4 characters', 'نیا پاس ورڈ کم از کم 4 حروف کا ہو'),
                        ),
                      ),
                    );
                  }
                  return;
                }

                if (newCtrl.text != confirmCtrl.text) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _text('Passwords do not match', 'پاس ورڈ ایک جیسے نہیں ہیں'),
                        ),
                      ),
                    );
                  }
                  return;
                }

                final updated = await AuthService.updatePassword(
                  currentEmail,
                  newCtrl.text,
                );
                if (!updated) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _text('User not found', 'صارف نہیں ملا'),
                        ),
                      ),
                    );
                  }
                  return;
                }
                await AuthService.endSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _text('Password changed successfully', 'پاس ورڈ کامیابی سے تبدیل ہوگیا'),
                      ),
                    ),
                  );
                }
                Get.offAllNamed(
                  '/login',
                  arguments: {'skipAutoLogin': true},
                );
              },
              child: Text(_text('Save', 'محفوظ کریں')),
            ),
          ],
        );
      },
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_text('Help', 'مدد')),
          content: Text(
            _text(
              'For support:\n1. Contact admin\n2. Verify internet\n3. Restart app if needed',
              'مدد کے لیے:\n1. ایڈمن سے رابطہ کریں\n2. انٹرنیٹ چیک کریں\n3. ضرورت ہو تو ایپ دوبارہ چلائیں',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(_text('OK', 'ٹھیک ہے')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_text('Settings', 'سیٹنگز')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              value: isDarkMode,
              onChanged: _toggleTheme,
              title: Text(_text('Theme', 'تھیم')),
              subtitle: Text(_text('Enable dark mode', 'ڈارک موڈ آن کریں')),
              secondary: const Icon(Icons.brightness_6),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(_text('Language', 'زبان')),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: languageCode,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ur', child: Text('اردو')),
                  ],
                  onChanged: _changeLanguage,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: Text(_text('Change Password', 'پاس ورڈ تبدیل کریں')),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(_text('Help', 'مدد')),
              onTap: _showHelpDialog,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                _text('Logout', 'لاگ آؤٹ'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
