import 'fruit.dart';

class CartItem {
  Fruit fruit;
  int qty;

  CartItem({required this.fruit, required this.qty});

  int get total => fruit.price * qty;
}
