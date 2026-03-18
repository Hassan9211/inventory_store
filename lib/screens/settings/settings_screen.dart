import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../services/auth_service.dart';
import '../../controllers/supplier_controller.dart';
import '../../core/constants/strings.dart';
import '../../routes/app_routes.dart';
import '../../screens/change_password_screen.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseService.getSettings();
    _storeCtrl.text =
        settings['storeName']?.toString() ?? AppStrings.defaultStoreName;
    _currencyCtrl.text =
        settings['currency']?.toString() ?? AppStrings.defaultCurrency;
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final salesController = Get.find<SalesController>();
    final supplierController = Get.find<SupplierController>();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.settings),
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _storeCtrl,
                  decoration: const InputDecoration(labelText: 'Store Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currencyCtrl,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final storeName = _storeCtrl.text.trim();
                      final currency = _currencyCtrl.text.trim();
                      if (storeName.isEmpty || currency.isEmpty) {
                        _showMessage('Store name and currency are required.');
                        return;
                      }
                      await DatabaseService.updateSettings({
                        'storeName': storeName,
                        'currency': currency,
                      });
                      _showMessage('Settings saved.');
                    },
                    child: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup Data'),
                    subtitle: const Text('Save a local backup of your data'),
                    onTap: () async {
                      final path = await DatabaseService.backup();
                      _showMessage('Backup saved: $path');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore Backup'),
                    subtitle: const Text('Load data from the last backup'),
                    onTap: () async {
                      final ok = await DatabaseService.restore();
                      if (!ok) {
                        _showMessage('No backup found.');
                        return;
                      }
                      await productController.loadAll();
                      await supplierController.loadSuppliers();
                      await salesController.loadAll();
                      _showMessage('Backup restored successfully.');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Reset Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Clear all products, sales, and settings'),
                    onTap: () async {
                      final confirm = await _confirmReset(context);
                      if (confirm != true) return;
                      await DatabaseService.reset();
                      await productController.loadAll();
                      await supplierController.loadSuppliers();
                      await salesController.loadAll();
                      await _loadSettings();
                      _showMessage('All data has been reset.');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your password with OTP'),
                    onTap: () => Get.to(() => const ChangePasswordScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      final confirm = await _confirmLogout(context);
                      if (confirm != true) return;
                      await AuthService.endSession();
                      await DatabaseService.setActiveUser(null);
                      await productController.loadAll();
                      await supplierController.loadSuppliers();
                      await salesController.loadAll();
                      if (!context.mounted) return;
                      Get.offAllNamed(AppRoutes.login);
                    },
                  ),
                ),
              ],
            ),
    );
  }


  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReset(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text('This will delete all data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}


