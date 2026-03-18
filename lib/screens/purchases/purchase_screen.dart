import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../controllers/supplier_controller.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/helpers.dart';
import '../../models/purchase_model.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _selectedProductId = '';
  String _selectedSupplierId = '';

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final supplierController = Get.find<SupplierController>();
    final salesController = Get.find<SalesController>();

    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService.getSettings(),
      builder: (context, snapshot) {
        final currency =
            snapshot.data?['currency']?.toString() ??
            AppStrings.defaultCurrency;

        return Scaffold(
          drawer: const AppDrawer(currentRoute: AppRoutes.purchases),
          appBar: AppBar(title: const Text('Purchase (Stock In)')),
          body: Obx(() {
            final products = productController.products;
            final suppliers = supplierController.suppliers;

            if (products.isEmpty) {
              return const Center(
                child: Text('Add products first to record purchases.'),
              );
            }

            if (_selectedProductId.isNotEmpty &&
                products.isNotEmpty &&
                products.every((p) => p.id != _selectedProductId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedProductId = products.first.id;
                  _priceCtrl.text = products.first.purchasePrice.toString();
                });
              });
            }

            if (_selectedProductId.isEmpty && products.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedProductId = products.first.id;
                  _priceCtrl.text = products.first.purchasePrice.toString();
                });
              });
            }

            if (_selectedSupplierId.isNotEmpty &&
                suppliers.isNotEmpty &&
                suppliers.every((s) => s.id != _selectedSupplierId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedSupplierId = suppliers.first.id;
                });
              });
            }

            if (_selectedSupplierId.isEmpty && suppliers.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedSupplierId = suppliers.first.id;
                });
              });
            }

            final selectedProduct = productController.findProduct(
              _selectedProductId,
            );
            final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
            final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
            final total = qty * price;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedSupplierId.isEmpty
                      ? null
                      : _selectedSupplierId,
                  items: suppliers
                      .map(
                        (supplier) => DropdownMenuItem(
                          value: supplier.id,
                          child: Text(supplier.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedSupplierId = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductId.isEmpty
                      ? null
                      : _selectedProductId,
                  items: products
                      .map(
                        (product) => DropdownMenuItem(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedProductId = value;
                      final product = productController.findProduct(value);
                      if (product != null) {
                        _priceCtrl.text = product.purchasePrice.toString();
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E8DD)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatCurrency(total, currency),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final qty = int.tryParse(_qtyCtrl.text.trim());
                      final price = double.tryParse(_priceCtrl.text.trim());
                      if (qty == null || price == null) {
                        _showMessage('Please enter valid quantity and price.');
                        return;
                      }
                      if (qty <= 0 || price <= 0) {
                        _showMessage('Quantity and price must be > 0.');
                        return;
                      }
                      final product = selectedProduct;
                      final supplier = supplierController.getSupplierById(
                        _selectedSupplierId,
                      );
                      if (product == null || supplier == null) {
                        _showMessage('Select supplier and product.');
                        return;
                      }

                      final purchase = PurchaseModel.create(
                        productId: product.id,
                        productName: product.name,
                        supplierId: supplier.id,
                        supplierName: supplier.name,
                        quantity: qty,
                        purchasePrice: price,
                      );
                      await salesController.addPurchase(purchase);
                      _showMessage('Purchase saved and stock updated.');
                      _qtyCtrl.clear();
                      setState(() {});
                    },
                    child: const Text('Save Purchase'),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
