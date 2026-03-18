import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/supplier_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supplierController = Get.find<SupplierController>();
    final productController = Get.find<ProductController>();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.suppliers),
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.addSupplier),
            icon: const Icon(Icons.add),
            tooltip: 'Add supplier',
          ),
        ],
      ),
      body: Obx(
        () {
          final suppliers = supplierController.suppliers;
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return Card(
                child: ListTile(
                  title: Text(supplier.name),
                  subtitle: Text('${supplier.phone} ? ${supplier.address}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Get.toNamed(
                          AppRoutes.addSupplier,
                          arguments: supplier,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final inUse = productController.products.any(
                            (p) => p.supplierId == supplier.id,
                          );
                          if (inUse) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Supplier is linked to products and cannot be deleted.',
                                ),
                              ),
                            );
                            return;
                          }
                          await supplierController.deleteSupplier(supplier.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addSupplier),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
    );
  }
}
