import 'package:get/get.dart';

import '../core/constants/strings.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductController extends GetxController {
  final ProductService _service = ProductService();

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    final loadedProducts = await _service.fetchProducts();
    final loadedCategories = await _service.fetchCategories();

    categories.assignAll(loadedCategories);
    if (categories.isEmpty) {
      final defaultCategory = CategoryModel.create('General');
      categories.add(defaultCategory);
      await _service.saveCategories(categories);
    }

    products.assignAll(loadedProducts);
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (categories.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    categories.add(CategoryModel.create(trimmed));
    await _service.saveCategories(categories);
  }

  bool isCategoryInUse(String categoryId) {
    return products.any((p) => p.categoryId == categoryId);
  }

  Future<void> deleteCategory(String categoryId) async {
    categories.removeWhere((c) => c.id == categoryId);
    await _service.saveCategories(categories);
  }

  CategoryModel? getCategoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> addProduct(ProductModel product) async {
    products.add(product);
    await _service.saveProducts(products);
  }

  Future<void> updateProduct(ProductModel updated) async {
    final index = products.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    products[index] = updated;
    await _service.saveProducts(products);
  }

  Future<void> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    await _service.saveProducts(products);
  }

  ProductModel? findProduct(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<bool> reduceStock(String productId, int qty) async {
    final product = findProduct(productId);
    if (product == null) return false;
    if (product.quantity < qty) return false;
    product.quantity -= qty;
    await _service.saveProducts(products);
    products.refresh();
    return true;
  }

  Future<void> increaseStock(String productId, int qty) async {
    final product = findProduct(productId);
    if (product == null) return;
    product.quantity += qty;
    await _service.saveProducts(products);
    products.refresh();
  }

  String get defaultCurrency => AppStrings.defaultCurrency;
}
