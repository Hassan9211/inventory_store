import 'package:get/get.dart';

import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

class SupplierController extends GetxController {
  final SupplierService _service = SupplierService();
  final RxList<SupplierModel> suppliers = <SupplierModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    final loaded = await _service.fetchSuppliers();
    suppliers.assignAll(loaded);

    if (suppliers.isEmpty) {
      suppliers.add(
        SupplierModel.create(
          name: 'Default Supplier',
          phone: '0000000',
          address: 'N/A',
        ),
      );
      await _service.saveSuppliers(suppliers);
    }
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    suppliers.add(supplier);
    await _service.saveSuppliers(suppliers);
  }

  Future<void> updateSupplier(SupplierModel updated) async {
    final index = suppliers.indexWhere((s) => s.id == updated.id);
    if (index == -1) return;
    suppliers[index] = updated;
    await _service.saveSuppliers(suppliers);
  }

  Future<void> deleteSupplier(String id) async {
    suppliers.removeWhere((s) => s.id == id);
    await _service.saveSuppliers(suppliers);
  }

  SupplierModel? getSupplierById(String id) {
    for (final supplier in suppliers) {
      if (supplier.id == id) return supplier;
    }
    return null;
  }
}
