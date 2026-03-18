import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/product_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.categories),
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context, productController),
            icon: const Icon(Icons.add),
            tooltip: 'Add category',
          ),
        ],
      ),
      body: Obx(
        () {
          final categories = productController.categories;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (productController.isCategoryInUse(category.id)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Category is used by products and cannot be deleted.',
                            ),
                          ),
                        );
                        return;
                      }
                      await productController.deleteCategory(category.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, productController),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    ProductController controller,
  ) async {
    final ctrl = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: 'Category Name',
              errorText: errorText,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitCategory(
              dialogContext,
              ctrl,
              setStateDialog,
              () => errorText = 'Category name required.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitCategory(
                dialogContext,
                ctrl,
                setStateDialog,
                () => errorText = 'Category name required.',
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    final name = result?.trim() ?? '';
    if (name.isEmpty) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    await controller.addCategory(name);
  }

  void _submitCategory(
    BuildContext dialogContext,
    TextEditingController ctrl,
    void Function(void Function()) setStateDialog,
    void Function() setError,
  ) {
    final name = ctrl.text.trim();
    if (name.isEmpty) {
      setStateDialog(() {
        setError();
      });
      return;
    }
    Navigator.of(dialogContext).pop(name);
  }
}






