import '../core/utils/helpers.dart';

class ProductModel {
  final String id;
  String name;
  String categoryId;
  String categoryName;
  double purchasePrice;
  double salePrice;
  int quantity;
  String supplierId;
  String supplierName;
  DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.purchasePrice,
    required this.salePrice,
    required this.quantity,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
  });

  factory ProductModel.create({
    required String name,
    required String categoryId,
    required String categoryName,
    required double purchasePrice,
    required double salePrice,
    required int quantity,
    required String supplierId,
    required String supplierName,
  }) {
    return ProductModel(
      id: generateId(),
      name: name,
      categoryId: categoryId,
      categoryName: categoryName,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      quantity: quantity,
      supplierId: supplierId,
      supplierName: supplierName,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'quantity': quantity,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? generateId(),
      name: json['name']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      purchasePrice: _toDouble(json['purchasePrice']),
      salePrice: _toDouble(json['salePrice']),
      quantity: _toInt(json['quantity']),
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
