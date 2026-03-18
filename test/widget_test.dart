import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:inventory_store/controllers/product_controller.dart';
import 'package:inventory_store/controllers/sales_controller.dart';
import 'package:inventory_store/controllers/supplier_controller.dart';
import 'package:inventory_store/main.dart';
import 'package:inventory_store/services/database_service.dart';

void main() {
  testWidgets('shows dashboard overview', (WidgetTester tester) async {
    Get.testMode = true;
    await DatabaseService.reset();
    Get.put(ProductController());
    Get.put(SupplierController());
    Get.put(SalesController());

    await tester.pumpWidget(const InventoryApp());
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
