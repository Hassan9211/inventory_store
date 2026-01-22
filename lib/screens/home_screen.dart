// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import '../models/fruit.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';
import 'bill_screen.dart';

class AddFruitDialog extends StatefulWidget {
  final Function(String, int, int) onAdd;

  const AddFruitDialog({required this.onAdd});

  @override
  State<AddFruitDialog> createState() => _AddFruitDialogState();
}

class _AddFruitDialogState extends State<AddFruitDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Fruit Name"),
          ),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(hintText: "Price"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: qtyController,
            decoration: const InputDecoration(hintText: "Quantity"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            widget.onAdd(
              nameController.text,
              int.parse(priceController.text),
              int.parse(qtyController.text),
            );
            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    super.dispose();
  }
}

class EditFruitDialog extends StatefulWidget {
  final Fruit fruit;
  final Function(Fruit, int, int) onUpdate;

  const EditFruitDialog({required this.fruit, required this.onUpdate});

  @override
  State<EditFruitDialog> createState() => _EditFruitDialogState();
}

class _EditFruitDialogState extends State<EditFruitDialog> {
  late TextEditingController priceController;
  late TextEditingController qtyController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.fruit.price.toString(),
    );
    qtyController = TextEditingController(
      text: widget.fruit.quantity.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: priceController,
            decoration: const InputDecoration(hintText: "Price"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: qtyController,
            decoration: const InputDecoration(hintText: "Quantity"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            widget.onUpdate(
              widget.fruit,
              int.parse(priceController.text),
              int.parse(qtyController.text),
            );
            Navigator.pop(context);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    qtyController.dispose();
    super.dispose();
  }
}

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
      ).showSnackBar(const SnackBar(content: Text("Invalid quantity")));
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

  // 🧾 CHECKOUT
  Future<void> checkout() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cart is empty")));
      return;
    }

    final billItems = cart
        .map((e) => CartItem(fruit: e.fruit, qty: e.qty))
        .toList();

    for (var item in billItems) {
      item.fruit.quantity -= item.qty;
    }

    await StorageService.saveFruits(fruits);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BillScreen(cart: billItems)),
    );

    cart.clear();
    setState(() {});
  }

  // ❌ DELETE FRUIT
  void deleteFruit(Fruit f) async {
    fruits.removeWhere((e) => e.id == f.id);
    filtered = fruits;
    await StorageService.saveFruits(fruits);
    setState(() {});
  }

  // ✏️ UPDATE FRUIT
  void updateFruit(Fruit fruit, int price, int qty) async {
    fruit.price = price;
    fruit.quantity = qty;
    await StorageService.saveFruits(fruits);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isTablet = c.maxWidth > 600;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Fruit Inventory"),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: checkout,
              ),
              IconButton(
                icon: const Icon(Icons.backup),
                onPressed: () async {
                  await StorageService.backup(fruits);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Backup Created")),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () async {
                  fruits = await StorageService.restore();
                  filtered = fruits;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Backup Restored")),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddFruitDialog(onAdd: addFruit),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search fruit...",
                    prefixIcon: const Icon(Icons.search),
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
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final f = filtered[i];
                      return Dismissible(
                        key: ValueKey(f.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => deleteFruit(f),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              f.name,
                              style: TextStyle(fontSize: isTablet ? 20 : 16),
                            ),
                            subtitle: Text("Rs ${f.price} | Qty ${f.quantity}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              onPressed: () => addToCart(f, 1),
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => EditFruitDialog(
                                fruit: f,
                                onUpdate: updateFruit,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
