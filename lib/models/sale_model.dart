import '../core/utils/helpers.dart';

class SaleModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double salePrice;
  final double total;
  final DateTime date;

  SaleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.salePrice,
    required this.total,
    required this.date,
  });

  factory SaleModel.create({
    required String productId,
    required String productName,
    required int quantity,
    required double salePrice,
  }) {
    final total = salePrice * quantity;
    return SaleModel(
      id: generateId(),
      productId: productId,
      productName: productName,
      quantity: quantity,
      salePrice: salePrice,
      total: total,
      date: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'salePrice': salePrice,
    'total': total,
    'date': date.toIso8601String(),
  };

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id']?.toString() ?? generateId(),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      salePrice: _toDouble(json['salePrice']),
      total: _toDouble(json['total']),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
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
