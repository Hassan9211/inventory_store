import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sales_controller.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesController = Get.find<SalesController>();

    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService.getSettings(),
      builder: (context, snapshot) {
        final currency =
            snapshot.data?['currency']?.toString() ??
                AppStrings.defaultCurrency;

        return Scaffold(
          drawer: const AppDrawer(currentRoute: AppRoutes.reports),
          appBar: AppBar(title: const Text('Reports')),
          body: Obx(
            () {
              final todaySales = salesController.todaySalesTotal;
              final monthlySales = salesController.monthlySalesTotal;
              final totalProfit = salesController.totalProfit;
              final totalSales = salesController.totalSales;
              final totalPurchases = salesController.totalPurchases;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _metricCard(
                    title: 'Daily Sales',
                    value: formatCurrency(todaySales, currency),
                    subtitle: formatDate(DateTime.now()),
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    title: 'Monthly Sales',
                    value: formatCurrency(monthlySales, currency),
                    subtitle: '${DateTime.now().year}-${DateTime.now().month}',
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    title: 'Total Profit',
                    value: formatCurrency(totalProfit, currency),
                    subtitle: 'Sales - Purchases',
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Purchase vs Sales'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Purchases'),
                              const SizedBox(height: 6),
                              Text(
                                formatCurrency(totalPurchases, currency),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Sales'),
                              const SizedBox(height: 6),
                              Text(
                                formatCurrency(totalSales, currency),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF6B6B6B))),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B6B6B))),
          ],
        ),
      ),
    );
  }
}
