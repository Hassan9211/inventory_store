import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final salesController = Get.find<SalesController>();

    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService.getSettings(),
      builder: (context, snapshot) {
        final storeName =
            snapshot.data?['storeName']?.toString() ??
                AppStrings.defaultStoreName;
        final currency =
            snapshot.data?['currency']?.toString() ??
                AppStrings.defaultCurrency;

        return Scaffold(
          drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
          appBar: AppBar(
            title: Text(storeName),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.settings),
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: Obx(
            () {
              final products = productController.products;
              final totalProducts = products.length;
              final totalStock = products.fold<int>(
                0,
                (sum, item) => sum + item.quantity,
              );
              final lowStock = products
                  .where((p) => p.quantity <= AppConstants.lowStockThreshold)
                  .toList();
              final todaySales = salesController.todaySalesTotal;
              final recent = salesController.recentTransactions;

              return RefreshIndicator(
                onRefresh: () async {
                  await productController.loadAll();
                  await salesController.loadAll();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Overview'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _summaryCard(
                          title: 'Total Products',
                          value: totalProducts.toString(),
                          icon: Icons.inventory_2,
                        ),
                        _summaryCard(
                          title: 'Total Stock',
                          value: totalStock.toString(),
                          icon: Icons.stacked_bar_chart,
                        ),
                        _summaryCard(
                          title: 'Low Stock Items',
                          value: lowStock.length.toString(),
                          icon: Icons.warning_amber_outlined,
                        ),
                        _summaryCard(
                          title: 'Today Sales',
                          value: formatCurrency(todaySales, currency),
                          icon: Icons.point_of_sale,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.addProduct),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.sales),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('New Sale'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('Low Stock Alerts'),
                    const SizedBox(height: 12),
                    if (lowStock.isEmpty)
                      _emptyState('All good. No low stock items.'),
                    if (lowStock.isNotEmpty)
                      Column(
                        children: lowStock
                            .take(5)
                            .map(
                              (item) => Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.error_outline,
                                    color: AppColors.danger,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    'Qty: ${item.quantity} ? Category: ${item.categoryName}',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 24),
                    _sectionTitle('Recent Transactions'),
                    const SizedBox(height: 12),
                    if (recent.isEmpty)
                      _emptyState('No recent transactions yet.'),
                    if (recent.isNotEmpty)
                      Column(
                        children: recent
                            .map(
                              (entry) => Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: entry.type == 'Sale'
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.info.withValues(alpha: 0.1),
                                    child: Icon(
                                      entry.type == 'Sale'
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      color: entry.type == 'Sale'
                                          ? AppColors.success
                                          : AppColors.info,
                                    ),
                                  ),
                                  title: Text(entry.title),
                                  subtitle: Text(
                                    '${entry.type} ? Qty ${entry.quantity} ? ${formatShortDate(entry.date)}',
                                  ),
                                  trailing: Text(
                                    formatCurrency(entry.total, currency),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E1DC)),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}
