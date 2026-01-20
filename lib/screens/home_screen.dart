// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import '../models/fruit.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';
import 'bill_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Fruit> fruits = [];
  List<Fruit> filtered = [];
  List<CartItem> cart = [];
  String query = "";

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    fruits = await StorageService.loadFruits();
    filtered = fruits;
    setState(() {});
  }

  void addFruit(String name, int price, int qty) async {
    fruits.add(
      Fruit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        quantity: qty,
      ),
    );
    await StorageService.saveFruits(fruits);
    filtered = fruits;
    setState(() {});
  }

  // 🛒 ADD TO CART
  void addToCart(Fruit fruit, int qty) {
    if (qty <= 0 || qty > fruit.quantity) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid quantity")));
      return;
    }

    final index = cart.indexWhere((c) => c.fruit.id == fruit.id);

    if (index != -1) {
      cart[index].qty += qty;
    } else {
      cart.add(CartItem(fruit: fruit, qty: qty));
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("${fruit.name} added to cart")));

    setState(() {});
  }

  // 🧾 CHECKOUT (FIXED)
  Future<void> checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cart is empty")));
      return;
    }

    // ✅ COPY CART DATA
    final billItems = cart
        .map((e) => CartItem(fruit: e.fruit, qty: e.qty))
        .toList();

    // 📦 UPDATE STOCK
    for (var item in billItems) {
      item.fruit.quantity -= item.qty;
    }

    await StorageService.saveFruits(fruits);

    // 👉 OPEN BILL SCREEN WITH COPY
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillScreen(cart: billItems)),
    );

    // 🧹 CLEAR CART AFTER RETURN
    cart.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Fruit Inventory"),
        actions: [
          IconButton(icon: Icon(Icons.shopping_cart), onPressed: checkout),
          IconButton(
            icon: Icon(Icons.backup),
            onPressed: () async {
              await StorageService.backup(fruits);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Backup Created")));
            },
          ),
          IconButton(
            icon: Icon(Icons.restore),
            onPressed: () async {
              fruits = await StorageService.restore();
              filtered = fruits;
              setState(() {});
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Backup Restored")));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AddFruitDialog(onAdd: addFruit),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search fruit...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                query = value.toLowerCase();
                filtered = fruits
                    .where((f) => f.name.toLowerCase().contains(query))
                    .toList();
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final f = filtered[i];
                return ListTile(
                  title: Text(f.name),
                  subtitle: Text("Rs ${f.price} | Qty ${f.quantity}"),
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (_) => BuyFruitDialog(
                      fruit: f,
                      onBuy: (qty) => addToCart(f, qty),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🛒 BUY DIALOG
class BuyFruitDialog extends StatelessWidget {
  final Fruit fruit;
  final Function(int qty) onBuy;

  BuyFruitDialog({required this.fruit, required this.onBuy});

  final qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Buy ${fruit.name}"),
      content: TextField(
        controller: qtyCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "Quantity",
          hintText: "Available: ${fruit.quantity}",
        ),
      ),
      actions: [
        TextButton(
          child: Text("ADD TO CART"),
          onPressed: () {
            onBuy(int.parse(qtyCtrl.text));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class AddFruitDialog extends StatelessWidget {
  final Function(String, int, int) onAdd;

  AddFruitDialog({required this.onAdd});

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: "Fruit Name"),
          ),
          TextField(
            controller: priceCtrl,
            decoration: InputDecoration(labelText: "Price"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: qtyCtrl,
            decoration: InputDecoration(labelText: "Quantity"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text("ADD"),
          onPressed: () {
            onAdd(
              nameCtrl.text.trim(),
              int.parse(priceCtrl.text),
              int.parse(qtyCtrl.text),
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
