import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_controller.dart';
import '../../models/supplier_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_drawer.dart';

class AddSupplierScreen extends StatefulWidget {
  final SupplierModel? supplier;

  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameCtrl.text = widget.supplier!.name;
      _phoneCtrl.text = widget.supplier!.phone;
      _addressCtrl.text = widget.supplier!.address;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierController = Get.find<SupplierController>();

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.addSupplier),
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                final phone = _phoneCtrl.text.trim();
                final address = _addressCtrl.text.trim();

                if (name.isEmpty || phone.isEmpty || address.isEmpty) {
                  _showMessage('Please fill all fields.');
                  return;
                }

                if (widget.supplier == null) {
                  final supplier = SupplierModel.create(
                    name: name,
                    phone: phone,
                    address: address,
                  );
                  await supplierController.addSupplier(supplier);
                  _showMessage('Supplier added.');
                } else {
                  final updated = SupplierModel(
                    id: widget.supplier!.id,
                    name: name,
                    phone: phone,
                    address: address,
                    createdAt: widget.supplier!.createdAt,
                  );
                  await supplierController.updateSupplier(updated);
                  _showMessage('Supplier updated.');
                }

                Get.offNamed(AppRoutes.suppliers);
              },
              child: Text(
                widget.supplier == null ? 'Save Supplier' : 'Update Supplier',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
