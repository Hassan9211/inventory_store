import '../models/supplier_model.dart';
import 'database_service.dart';

class SupplierService {
  Future<List<SupplierModel>> fetchSuppliers() async {
    final data = await DatabaseService.getCollection('suppliers');
    return data.map(SupplierModel.fromJson).toList();
  }

  Future<void> saveSuppliers(List<SupplierModel> suppliers) async {
    final data = suppliers.map((e) => e.toJson()).toList();
    await DatabaseService.setCollection('suppliers', data);
  }
}
