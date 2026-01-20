// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import '../models/fruit.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Fruit> fruits = [];
  List<Fruit> filtered = [];
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

  // 🔥 BUY FUNCTION
  void buyFruit(Fruit fruit, int qty) async {
    if (qty <= 0 || qty > fruit.quantity) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid quantity")));
      return;
    }

    int total = qty * fruit.price;
    fruit.quantity -= qty;

    await StorageService.saveFruits(fruits);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🧾 Bought $qty ${fruit.name} | Total: Rs $total"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Fruit Inventory"),
        actions: [
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
          // 🔍 SEARCH BAR
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

          // 📃 LIST
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final f = filtered[i];

                return Dismissible(
                  key: ValueKey(f.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    fruits.removeWhere((e) => e.id == f.id);
                    filtered.removeAt(i);
                    await StorageService.saveFruits(fruits);
                    setState(() {});
                  },
                  child: ListTile(
                    title: Text(f.name),
                    subtitle: Text("Rs ${f.price} | Qty ${f.quantity}"),
                    trailing: f.quantity <= 5
                        ? Icon(Icons.warning, color: Colors.red)
                        : null,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => UpdatePriceDialog(
                        fruit: f,
                        onUpdate: () async {
                          await StorageService.saveFruits(fruits);
                          setState(() {});
                        },
                      ),
                    ),
                    onLongPress: () => showDialog(
                      context: context,
                      builder: (_) => BuyFruitDialog(
                        fruit: f,
                        onBuy: (qty) => buyFruit(f, qty),
                      ),
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

// ➕ ADD FRUIT DIALOG
class AddFruitDialog extends StatelessWidget {
  final Function(String, int, int) onAdd;
  AddFruitDialog({required this.onAdd});

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: "Name"),
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
              nameCtrl.text,
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

// ✏ UPDATE PRICE DIALOG
class UpdatePriceDialog extends StatelessWidget {
  final Fruit fruit;
  final VoidCallback onUpdate;

  UpdatePriceDialog({required this.fruit, required this.onUpdate});

  final priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    priceCtrl.text = fruit.price.toString();

    return AlertDialog(
      title: Text("Update Price"),
      content: TextField(
        controller: priceCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: "New Price"),
      ),
      actions: [
        TextButton(
          child: Text("UPDATE"),
          onPressed: () {
            fruit.price = int.parse(priceCtrl.text);
            onUpdate();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

// 🛒 BUY DIALOG (Customer Purchase)
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
          child: Text("BUY"),
          onPressed: () {
            int qty = int.parse(qtyCtrl.text);
            onBuy(qty);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
