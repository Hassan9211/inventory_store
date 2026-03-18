import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/sales_controller.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/helpers.dart';
import '../../models/sale_model.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../widgets/app_drawer.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _selectedProductId = '';

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final salesController = Get.find<SalesController>();

    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService.getSettings(),
      builder: (context, snapshot) {
        final currency =
            snapshot.data?['currency']?.toString() ??
            AppStrings.defaultCurrency;
        final storeName =
            snapshot.data?['storeName']?.toString() ??
            AppStrings.defaultStoreName;

        return Scaffold(
          drawer: const AppDrawer(currentRoute: AppRoutes.sales),
          appBar: AppBar(title: const Text('Sales (Stock Out)')),
          body: Obx(() {
            final products = productController.products;

            if (products.isEmpty) {
              return const Center(
                child: Text('Add products first to record sales.'),
              );
            }

            if (_selectedProductId.isNotEmpty &&
                products.isNotEmpty &&
                products.every((p) => p.id != _selectedProductId)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedProductId = products.first.id;
                  _priceCtrl.text = products.first.salePrice.toString();
                });
              });
            }

            if (_selectedProductId.isEmpty && products.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedProductId = products.first.id;
                  _priceCtrl.text = products.first.salePrice.toString();
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
                        _priceCtrl.text = product.salePrice.toString();
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Product'),
                ),
                const SizedBox(height: 12),
                if (selectedProduct != null)
                  Text(
                    'In stock: ${selectedProduct.quantity}',
                    style: const TextStyle(color: Color(0xFF6B6B6B)),
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
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Sale Price'),
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
                      if (qty == null) {
                        _showMessage('Please enter quantity.');
                        return;
                      }
                      if (qty <= 0) {
                        _showMessage('Quantity must be > 0.');
                        return;
                      }
                      final product = selectedProduct;
                      if (product == null) {
                        _showMessage('Please select a product.');
                        return;
                      }
                      if (qty > product.quantity) {
                        _showMessage('Not enough stock available.');
                        return;
                      }

                      final sale = SaleModel.create(
                        productId: product.id,
                        productName: product.name,
                        quantity: qty,
                        salePrice: product.salePrice,
                      );
                      final remainingStock = product.quantity - qty;
                      final ok = await salesController.addSale(sale);
                      if (!ok) {
                        _showMessage('Sale failed. Check stock.');
                        return;
                      }

                      _showReceipt(sale, currency, storeName, remainingStock);
                      _qtyCtrl.clear();
                      setState(() {});
                    },
                    child: const Text('Save Sale'),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  void _showReceipt(
    SaleModel sale,
    String currency,
    String storeName,
    int remaining,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sale Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${sale.productName}'),
            const SizedBox(height: 6),
            Text('Quantity: ${sale.quantity}'),
            const SizedBox(height: 6),
            Text('Price: ${formatCurrency(sale.salePrice, currency)}'),
            const SizedBox(height: 6),
            Text(
              'Total: ${formatCurrency(sale.total, currency)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Remaining Stock: $remaining'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final pdfBytes = await InvoicePdfService.buildSaleReceipt(
                  storeName: storeName,
                  sale: sale,
                  currency: currency,
                  remainingStock: remaining,
                );
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: 'sale_${sale.id}.pdf',
                );
              } catch (e) {
                if (!mounted) return;
                _showMessage('PDF export failed: ${e.toString()}');
              }
            },
            child: const Text('Save PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}






