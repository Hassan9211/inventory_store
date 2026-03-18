import '../models/category_model.dart';
import '../models/product_model.dart';
import 'database_service.dart';

class ProductService {
  Future<List<ProductModel>> fetchProducts() async {
    final data = await DatabaseService.getCollection('products');
    return data.map(ProductModel.fromJson).toList();
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final data = products.map((e) => e.toJson()).toList();
    await DatabaseService.setCollection('products', data);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final data = await DatabaseService.getCollection('categories');
    return data.map(CategoryModel.fromJson).toList();
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    final data = categories.map((e) => e.toJson()).toList();
    await DatabaseService.setCollection('categories', data);
  }
}
