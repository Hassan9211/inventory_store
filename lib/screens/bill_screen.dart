import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class BillScreen extends StatelessWidget {
  final List<CartItem> cart;

  BillScreen({required this.cart});

  int get grandTotal => cart.fold(0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Bill"), centerTitle: true),
      body: cart.isEmpty
          ? Center(child: Text("No items in cart"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (_, i) {
                      final item = cart[i];
                      return ListTile(
                        title: Text(item.fruit.name),
                        subtitle: Text("Rs ${item.fruit.price} x ${item.qty}"),
                        trailing: Text(
                          "Rs ${item.total}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.green.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rs $grandTotal",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("DONE"),
                  ),
                ),
              ],
            ),
    );
  }
}
