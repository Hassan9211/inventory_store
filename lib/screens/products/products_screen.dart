import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../core/constants/strings.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/product_card.dart';
import '../../models/product_model.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _applyFilters(
    List<ProductModel> products,
    String categoryId,
    String query,
  ) {
    var filtered = products;
    if (categoryId != 'all') {
      filtered = filtered.where((p) => p.categoryId == categoryId).toList();
    }
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      filtered = filtered
          .where((p) => p.name.toLowerCase().contains(lower))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();

    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseService.getSettings(),
      builder: (context, snapshot) {
        final currency =
            snapshot.data?['currency']?.toString() ??
            AppStrings.defaultCurrency;

        return Scaffold(
          drawer: const AppDrawer(currentRoute: AppRoutes.products),
          appBar: AppBar(
            title: const Text('Products'),
            actions: [
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.addProduct),
                icon: const Icon(Icons.add),
                tooltip: 'Add product',
              ),
            ],
          ),
          body: Obx(() {
            final categories = productController.categories;
            final products = productController.products;
            final filtered = _applyFilters(
              products,
              _selectedCategoryId,
              _searchQuery,
            );

            return RefreshIndicator(
              onRefresh: () async {
                await productController.loadAll();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Search products',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Filter:'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryId,
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All Categories'),
                            ),
                            ...categories.map(
                              (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty) _emptyState('No products found.'),
                  if (filtered.isNotEmpty)
                    ...filtered.map(
                      (product) => ProductCard(
                        product: product,
                        currency: currency,
                        onEdit: () {
                          Get.toNamed(AppRoutes.addProduct, arguments: product);
                        },
                        onDelete: () async {
                          final confirmed = await _confirmDelete(context);
                          if (confirmed != true) return;
                          await productController.deleteProduct(product.id);
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Get.toNamed(AppRoutes.addProduct),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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
      child: Center(child: Text(text)),
    );
  }
}
