import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/strings.dart';
import '../routes/app_routes.dart';
import '../services/database_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: DatabaseService.getSettings(),
              builder: (context, snapshot) {
                final storeName =
                    snapshot.data?['storeName']?.toString() ??
                        AppStrings.defaultStoreName;
                return DrawerHeader(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Inventory Management'),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _navTile(
                    title: 'Dashboard',
                    icon: Icons.dashboard,
                    route: AppRoutes.dashboard,
                  ),
                  _navTile(
                    title: 'Products',
                    icon: Icons.inventory_2,
                    route: AppRoutes.products,
                  ),
                  _navTile(
                    title: 'Categories',
                    icon: Icons.category,
                    route: AppRoutes.categories,
                  ),
                  _navTile(
                    title: 'Suppliers',
                    icon: Icons.local_shipping,
                    route: AppRoutes.suppliers,
                  ),
                  _navTile(
                    title: 'Purchases',
                    icon: Icons.add_box,
                    route: AppRoutes.purchases,
                  ),
                  _navTile(
                    title: 'Sales',
                    icon: Icons.point_of_sale,
                    route: AppRoutes.sales,
                  ),
                  _navTile(
                    title: 'Reports',
                    icon: Icons.bar_chart,
                    route: AppRoutes.reports,
                  ),
                  _navTile(
                    title: 'Settings',
                    icon: Icons.settings,
                    route: AppRoutes.settings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile({
    required String title,
    required IconData icon,
    required String route,
  }) {
    final selected = currentRoute == route;
    return ListTile(
      selected: selected,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        if (selected) {
          Get.back();
          return;
        }
        Get.offNamed(route);
      },
    );
  }
}
