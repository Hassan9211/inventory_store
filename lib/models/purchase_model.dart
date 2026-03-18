import '../core/utils/helpers.dart';

class PurchaseModel {
  final String id;
  final String productId;
  final String productName;
  final String supplierId;
  final String supplierName;
  final int quantity;
  final double purchasePrice;
  final double total;
  final DateTime date;

  PurchaseModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.purchasePrice,
    required this.total,
    required this.date,
  });

  factory PurchaseModel.create({
    required String productId,
    required String productName,
    required String supplierId,
    required String supplierName,
    required int quantity,
    required double purchasePrice,
  }) {
    final total = purchasePrice * quantity;
    return PurchaseModel(
      id: generateId(),
      productId: productId,
      productName: productName,
      supplierId: supplierId,
      supplierName: supplierName,
      quantity: quantity,
      purchasePrice: purchasePrice,
      total: total,
      date: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'quantity': quantity,
    'purchasePrice': purchasePrice,
    'total': total,
    'date': date.toIso8601String(),
  };

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id']?.toString() ?? generateId(),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      supplierId: json['supplierId']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      purchasePrice: _toDouble(json['purchasePrice']),
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
