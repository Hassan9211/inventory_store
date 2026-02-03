// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Add Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Fruit Name",
              prefixIcon: Icon(Icons.local_grocery_store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: "Price",
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyController,
            decoration: const InputDecoration(
              labelText: "Quantity",
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
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
            final name = nameController.text.trim();
            final price = int.tryParse(priceController.text.trim());
            final qty = int.tryParse(qtyController.text.trim());

            if (name.isEmpty || price == null || qty == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter valid values")),
              );
              return;
            }

            if (price <= 0 || qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Price and quantity must be greater than 0"),
                ),
              );
              return;
            }

            widget.onAdd(name, price, qty);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Edit Fruit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: priceController,
            decoration: const InputDecoration(
              labelText: "Price",
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyController,
            decoration: const InputDecoration(
              labelText: "Quantity",
              prefixIcon: Icon(Icons.inventory_outlined),
            ),
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

  int get totalProducts => fruits.length;
  int get totalStock =>
      fruits.fold(0, (sum, item) => sum + item.quantity);

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

    await Get.to(() => BillScreen(cart: billItems));

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
        final isTablet = c.maxWidth >= 600 && c.maxWidth < 1024;
        final isDesktop = c.maxWidth >= 1024;
        final contentWidth = isDesktop
            ? 960.0
            : isTablet
                ? 720.0
                : double.infinity;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Fruit Inventory"),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: checkout,
                tooltip: 'Checkout',
              ),
              IconButton(
                icon: const Icon(Icons.backup),
                onPressed: () async {
                  await StorageService.backup(fruits);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Backup Created")),
                  );
                },
                tooltip: 'Backup',
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
                tooltip: 'Restore',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text("Add Fruit"),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddFruitDialog(onAdd: addFruit),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: EdgeInsets.all(isTablet || isDesktop ? 20 : 10),
                child: Column(
                  children: [
                    _summaryHeader(isTablet || isDesktop),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search fruits by name",
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        query = value.toLowerCase();
                        filtered = fruits
                            .where(
                              (f) => f.name.toLowerCase().contains(query),
                            )
                            .toList();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isDesktop
                          ? GridView.builder(
                              itemCount: filtered.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (_, i) => _fruitCard(
                                filtered[i],
                                isTablet: isTablet || isDesktop,
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _fruitCard(
                                filtered[i],
                                isTablet: isTablet,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryHeader(bool wide) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2, color: Color(0xFF1F7A4D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Inventory Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  "Products: $totalProducts • Total stock: $totalStock",
                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                ),
              ],
            ),
          ),
          if (wide)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Healthy Stock",
                style: TextStyle(
                  color: Color(0xFF1F7A4D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fruitCard(Fruit f, {required bool isTablet}) {
    return Dismissible(
      key: ValueKey(f.id),
      background: Container(
        color: const Color(0xFFD64545),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => deleteFruit(f),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          title: Text(
            f.name,
            style: TextStyle(fontSize: isTablet ? 18 : 16),
          ),
          subtitle: Text(
            "Rs ${f.price}",
            style: const TextStyle(color: Color(0xFF6B6B6B)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Qty ${f.quantity}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => addToCart(f, 1),
                tooltip: 'Add to cart',
              ),
            ],
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
  }
}
