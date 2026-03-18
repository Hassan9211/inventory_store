import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../controllers/supplier_controller.dart';
import '../../models/product_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _saleCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  String _selectedCategoryId = '';
  String _selectedSupplierId = '';

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _purchaseCtrl.text = widget.product!.purchasePrice.toString();
      _saleCtrl.text = widget.product!.salePrice.toString();
      _qtyCtrl.text = widget.product!.quantity.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _selectedSupplierId = widget.product!.supplierId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purchaseCtrl.dispose();
    _saleCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final supplierController = Get.find<SupplierController>();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.addProduct),
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Obx(() {
        final categories = productController.categories;
        final suppliers = supplierController.suppliers;

        if (_selectedCategoryId.isNotEmpty &&
            categories.isNotEmpty &&
            categories.every((c) => c.id != _selectedCategoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedCategoryId = categories.first.id;
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

        if (_selectedCategoryId.isEmpty && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedCategoryId = categories.first.id;
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId.isEmpty
                  ? null
                  : _selectedCategoryId,
              items: categories
                  .map(
                    (cat) =>
                        DropdownMenuItem(value: cat.id, child: Text(cat.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
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
            TextField(
              controller: _purchaseCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Purchase Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _saleCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sale Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final purchasePrice = double.tryParse(
                    _purchaseCtrl.text.trim(),
                  );
                  final salePrice = double.tryParse(_saleCtrl.text.trim());
                  final qty = int.tryParse(_qtyCtrl.text.trim());

                  if (name.isEmpty ||
                      purchasePrice == null ||
                      salePrice == null ||
                      qty == null) {
                    _showMessage('Please fill all fields with valid values.');
                    return;
                  }

                  if (purchasePrice <= 0 || salePrice <= 0 || qty < 0) {
                    _showMessage('Prices must be > 0 and qty >= 0.');
                    return;
                  }

                  final category = productController.getCategoryById(
                    _selectedCategoryId,
                  );
                  final supplier = supplierController.getSupplierById(
                    _selectedSupplierId,
                  );
                  if (category == null || supplier == null) {
                    _showMessage('Please select category and supplier.');
                    return;
                  }

                  if (widget.product == null) {
                    final product = ProductModel.create(
                      name: name,
                      categoryId: category.id,
                      categoryName: category.name,
                      purchasePrice: purchasePrice,
                      salePrice: salePrice,
                      quantity: qty,
                      supplierId: supplier.id,
                      supplierName: supplier.name,
                    );
                    await productController.addProduct(product);
                    _showMessage('Product added successfully.');
                    Get.offNamed(AppRoutes.products);
                    return;
                  }

                  final updated = ProductModel(
                    id: widget.product!.id,
                    name: name,
                    categoryId: category.id,
                    categoryName: category.name,
                    purchasePrice: purchasePrice,
                    salePrice: salePrice,
                    quantity: qty,
                    supplierId: supplier.id,
                    supplierName: supplier.name,
                    createdAt: widget.product!.createdAt,
                  );
                  await productController.updateProduct(updated);
                  _showMessage('Product updated successfully.');
                  Get.offNamed(AppRoutes.products);
                },
                child: Text(
                  widget.product == null ? 'Save Product' : 'Update Product',
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
