class Fruit {
  static const String qrPrefix = 'invfruit:';

  String id;
  String name;
  int price;
  int quantity;
  String barcode;

  Fruit({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.barcode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'barcode': barcode,
  };

  factory Fruit.fromJson(Map<String, dynamic> json) {
    return Fruit(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'],
      barcode: (json['barcode'] ?? json['id']).toString(),
    );
  }

  String get qrPayload => '$qrPrefix$id';
}
