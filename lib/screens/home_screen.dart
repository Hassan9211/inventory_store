// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/fruit.dart';
import '../models/cart_item.dart';
import '../services/storage_service.dart';
import '../widgets/app_router_widget.dart';
import 'barcode_scanner_screen.dart';
import 'qr_labels_screen.dart';

class AddFruitDialog extends StatefulWidget {
  final Function(String, int, int, String) onAdd;

  const AddFruitDialog({required this.onAdd});

  @override
  State<AddFruitDialog> createState() => _AddFruitDialogState();
}

class _AddFruitDialogState extends State<AddFruitDialog> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController();
  final barcodeController = TextEditingController();

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
          const SizedBox(height: 12),
          TextField(
            controller: barcodeController,
            decoration: const InputDecoration(
              labelText: "QR Code",
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final name = nameController.text.trim();
            final price = int.tryParse(priceController.text.trim());
            final qty = int.tryParse(qtyController.text.trim());
            final barcode = barcodeController.text.trim();

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

            widget.onAdd(name, price, qty, barcode);
            Get.back();
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
    barcodeController.dispose();
    super.dispose();
  }
}

class EditFruitDialog extends StatefulWidget {
  final Fruit fruit;
  final Function(Fruit, int, int, String) onUpdate;

  const EditFruitDialog({required this.fruit, required this.onUpdate});

  @override
  State<EditFruitDialog> createState() => _EditFruitDialogState();
}

class _EditFruitDialogState extends State<EditFruitDialog> {
  late TextEditingController priceController;
  late TextEditingController qtyController;
  late TextEditingController barcodeController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.fruit.price.toString(),
    );
    qtyController = TextEditingController(
      text: widget.fruit.quantity.toString(),
    );
    barcodeController = TextEditingController(
      text: widget.fruit.barcode,
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
          const SizedBox(height: 12),
          TextField(
            controller: barcodeController,
            decoration: const InputDecoration(
              labelText: "QR Code",
              prefixIcon: Icon(Icons.qr_code_2),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final price = int.tryParse(priceController.text.trim());
            final qty = int.tryParse(qtyController.text.trim());

            if (price == null || qty == null || price <= 0 || qty <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter valid values")),
              );
              return;
            }

            widget.onUpdate(
              widget.fruit,
              price,
              qty,
              barcodeController.text.trim(),
            );
            Get.back();
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
    barcodeController.dispose();
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
    filtered = List<Fruit>.from(fruits);
    if (mounted) {
      setState(() {});
    }
  }

  int get totalProducts => fruits.length;
  int get totalStock =>
      fruits.fold(0, (sum, item) => sum + item.quantity);
  int get totalCartItems =>
      cart.fold(0, (sum, item) => sum + item.qty);
  int get cartGrandTotal =>
      cart.fold(0, (sum, item) => sum + item.total);

  void addFruit(String name, int price, int qty, String barcode) async {
    final newFruit = Fruit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      quantity: qty,
      barcode: barcode.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : barcode,
    );

    fruits.add(
      newFruit,
    );
    filtered = List<Fruit>.from(fruits);
    setState(() {});

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fruit added, but save failed on this device"),
          ),
        );
      }
      debugPrint("Save fruits error: $e");
    }
  }

  // 🛒 ADD TO CART
  void addToCart(Fruit fruit, int qty) async {
    if (qty <= 0 || qty > fruit.quantity) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            fruit.quantity > 0
                ? "Only ${fruit.quantity} left in stock"
                : "No more stock available",
          ),
        ),
      );
      return;
    }

    fruit.quantity -= qty;
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

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      debugPrint("Add-to-cart save error: $e");
    }
  }

  // 🧾 CHECKOUT
  Future<void> removeFromCart(Fruit fruit, {int qty = 1}) async {
    final index = cart.indexWhere((c) => c.fruit.id == fruit.id);
    if (index == -1) return;

    final removedQty = qty > cart[index].qty ? cart[index].qty : qty;
    if (removedQty <= 0) return;

    cart[index].qty -= removedQty;
    fruit.quantity += removedQty;

    if (cart[index].qty <= 0) {
      cart.removeAt(index);
    }

    setState(() {});

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      debugPrint("Remove-from-cart save error: $e");
    }
  }

  Future<void> clearCart() async {
    if (cart.isEmpty) return;

    for (final item in cart) {
      item.fruit.quantity += item.qty;
    }
    cart.clear();

    setState(() {});

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      debugPrint("Clear-cart save error: $e");
    }
  }

  Future<void> openCartSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.65,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Manage Cart",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (cart.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Cart is empty",
                              style: TextStyle(color: Color(0xFF6B6B6B)),
                            ),
                          ),
                        ),
                      if (cart.isNotEmpty)
                        Expanded(
                          child: ListView.separated(
                            itemCount: cart.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final item = cart[i];
                              return Card(
                                child: ListTile(
                                  title: Text(item.fruit.name),
                                  subtitle: Text(
                                    "Rs ${item.fruit.price} x ${item.qty}",
                                    style: const TextStyle(
                                      color: Color(0xFF6B6B6B),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        tooltip: "Remove 1",
                                        onPressed: () async {
                                          await removeFromCart(item.fruit);
                                          modalSetState(() {});
                                        },
                                      ),
                                      Text(
                                        "${item.qty}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                        tooltip: "Remove item",
                                        onPressed: () async {
                                          await removeFromCart(
                                            item.fruit,
                                            qty: item.qty,
                                          );
                                          modalSetState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (cart.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4EC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD8E8DD)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Items: $totalCartItems",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Total: Rs $cartGrandTotal",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F7A4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await clearCart();
                                  modalSetState(() {});
                                },
                                icon: const Icon(Icons.clear_all),
                                label: const Text("Clear Cart"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.of(sheetContext).pop();
                                  await checkout();
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text("Checkout"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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

    bool saveFailed = false;
    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      saveFailed = true;
      debugPrint("Checkout save error: $e");
    }

    await Get.toNamed(AppRoutes.bill, arguments: billItems);

    if (saveFailed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bill opened, but stock changes could not be saved"),
        ),
      );
    }

    cart.clear();
    setState(() {});
  }

  // ❌ DELETE FRUIT
  void deleteFruit(Fruit f) async {
    fruits.removeWhere((e) => e.id == f.id);
    filtered = List<Fruit>.from(fruits);
    setState(() {});

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delete updated in UI, but save failed")),
        );
      }
      debugPrint("Delete save error: $e");
    }
  }

  // ✏️ UPDATE FRUIT
  void updateFruit(Fruit fruit, int price, int qty, String barcode) async {
    fruit.price = price;
    fruit.quantity = qty;
    fruit.barcode = barcode.isEmpty ? fruit.id : barcode;
    setState(() {});

    try {
      await StorageService.saveFruits(fruits);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update applied, but save failed")),
        );
      }
      debugPrint("Update save error: $e");
    }
  }

  Future<void> scanAndAddToCart() async {
    final scannedCode = await Get.to<String>(() => const BarcodeScannerScreen());
    if (scannedCode == null || scannedCode.trim().isEmpty) return;

    final rawCode = scannedCode.trim();
    final normalizedCode = rawCode.toLowerCase();
    Fruit? matchedFruit;

    if (normalizedCode.startsWith(Fruit.qrPrefix)) {
      final scannedId = rawCode.substring(Fruit.qrPrefix.length);
      for (final fruit in fruits) {
        if (fruit.id == scannedId) {
          matchedFruit = fruit;
          break;
        }
      }
    }

    if (matchedFruit == null) {
      for (final fruit in fruits) {
        if (fruit.barcode.trim().toLowerCase() == normalizedCode) {
          matchedFruit = fruit;
          break;
        }
      }
    }

    if (matchedFruit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No item found for QR code: $scannedCode")),
      );
      return;
    }

    addToCart(matchedFruit, 1);
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
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: scanAndAddToCart,
                tooltip: 'Scan QR code',
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                onPressed: () => Get.to(
                  () => QrLabelsScreen(fruits: List<Fruit>.from(fruits)),
                ),
                tooltip: 'QR labels',
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (totalCartItems > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD64545),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            "$totalCartItems",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: openCartSheet,
                tooltip: 'Cart',
              ),
              IconButton(
                icon: const Icon(Icons.backup),
                onPressed: () async {
                  try {
                    await StorageService.backup(fruits);
                    final path = await StorageService.backupPath();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Backup Created: $path")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Backup failed: ${e.runtimeType}")),
                    );
                    debugPrint("Backup error: $e");
                  }
                },
                tooltip: 'Backup',
              ),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () async {
                  try {
                    final restored = await StorageService.restore();
                    if (restored.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Backup is empty. First create backup, then restore.",
                          ),
                        ),
                      );
                      return;
                    }

                    fruits = restored;
                    filtered = List<Fruit>.from(fruits);
                    await StorageService.saveFruits(fruits);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Backup Restored (${fruits.length} items)"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Restore failed")),
                    );
                    debugPrint("Restore error: $e");
                  }
                },
                tooltip: 'Restore',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Get.toNamed(AppRoutes.settings),
                tooltip: 'Settings',
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
            "Rs ${f.price}\nQR: ${f.barcode}",
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
