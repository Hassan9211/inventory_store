import '../models/purchase_model.dart';
import '../models/sale_model.dart';
import 'database_service.dart';

class SalesService {
  Future<List<SaleModel>> fetchSales() async {
    final data = await DatabaseService.getCollection('sales');
    return data.map(SaleModel.fromJson).toList();
  }

  Future<void> saveSales(List<SaleModel> sales) async {
    final data = sales.map((e) => e.toJson()).toList();
    await DatabaseService.setCollection('sales', data);
  }

  Future<List<PurchaseModel>> fetchPurchases() async {
    final data = await DatabaseService.getCollection('purchases');
    return data.map(PurchaseModel.fromJson).toList();
  }

  Future<void> savePurchases(List<PurchaseModel> purchases) async {
    final data = purchases.map((e) => e.toJson()).toList();
    await DatabaseService.setCollection('purchases', data);
  }
}
