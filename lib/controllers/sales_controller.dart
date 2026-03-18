import 'package:get/get.dart';

import '../core/utils/helpers.dart';
import '../models/purchase_model.dart';
import '../models/sale_model.dart';
import '../services/sales_service.dart';
import 'product_controller.dart';

class TransactionEntry {
  final String type;
  final String title;
  final int quantity;
  final double total;
  final DateTime date;

  TransactionEntry({
    required this.type,
    required this.title,
    required this.quantity,
    required this.total,
    required this.date,
  });
}

class SalesController extends GetxController {
  final SalesService _service = SalesService();
  final RxList<SaleModel> sales = <SaleModel>[].obs;
  final RxList<PurchaseModel> purchases = <PurchaseModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    final loadedSales = await _service.fetchSales();
    final loadedPurchases = await _service.fetchPurchases();
    sales.assignAll(loadedSales);
    purchases.assignAll(loadedPurchases);
  }

  Future<bool> addSale(SaleModel sale) async {
    final productController = Get.find<ProductController>();
    final ok = await productController.reduceStock(sale.productId, sale.quantity);
    if (!ok) return false;
    sales.add(sale);
    await _service.saveSales(sales);
    return true;
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    final productController = Get.find<ProductController>();
    await productController.increaseStock(
      purchase.productId,
      purchase.quantity,
    );
    purchases.add(purchase);
    await _service.savePurchases(purchases);
  }

  double get todaySalesTotal {
    final now = DateTime.now();
    return sales
        .where((s) => isSameDay(s.date, now))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  double get monthlySalesTotal {
    final now = DateTime.now();
    return sales
        .where((s) => isSameMonth(s.date, now))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  double get totalSales {
    return sales.fold(0.0, (sum, item) => sum + item.total);
  }

  double get totalPurchases {
    return purchases.fold(0.0, (sum, item) => sum + item.total);
  }

  double get totalProfit => totalSales - totalPurchases;

  double salesForDay(DateTime day) {
    return sales
        .where((s) => isSameDay(s.date, day))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  double purchasesForDay(DateTime day) {
    return purchases
        .where((p) => isSameDay(p.date, day))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  List<TransactionEntry> get recentTransactions {
    final entries = <TransactionEntry>[];
    for (final sale in sales) {
      entries.add(
        TransactionEntry(
          type: 'Sale',
          title: sale.productName,
          quantity: sale.quantity,
          total: sale.total,
          date: sale.date,
        ),
      );
    }
    for (final purchase in purchases) {
      entries.add(
        TransactionEntry(
          type: 'Purchase',
          title: purchase.productName,
          quantity: purchase.quantity,
          total: purchase.total,
          date: purchase.date,
        ),
      );
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    if (entries.length <= 5) return entries;
    return entries.take(5).toList();
  }
}
