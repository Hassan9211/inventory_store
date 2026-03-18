import '../core/utils/helpers.dart';

class SupplierModel {
  final String id;
  String name;
  String phone;
  String address;
  DateTime createdAt;

  SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  factory SupplierModel.create({
    required String name,
    required String phone,
    required String address,
  }) {
    return SupplierModel(
      id: generateId(),
      name: name,
      phone: phone,
      address: address,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? generateId(),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
