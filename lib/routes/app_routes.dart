import 'package:get/get.dart';

import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/purchases/purchase_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/suppliers/add_supplier_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const dashboard = '/';
  static const products = '/products';
  static const addProduct = '/products/add';
  static const categories = '/categories';
  static const suppliers = '/suppliers';
  static const addSupplier = '/suppliers/add';
  static const purchases = '/purchases';
  static const sales = '/sales';
  static const reports = '/reports';
  static const settings = '/settings';
}

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.signup, page: () => const SignUpScreen()),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(name: AppRoutes.products, page: () => const ProductsScreen()),
    GetPage(
      name: AppRoutes.addProduct,
      page: () {
        final arg = Get.arguments;
        return AddProductScreen(
          product: arg is ProductModel ? arg : null,
        );
      },
    ),
    GetPage(name: AppRoutes.categories, page: () => const CategoriesScreen()),
    GetPage(name: AppRoutes.suppliers, page: () => const SuppliersScreen()),
    GetPage(
      name: AppRoutes.addSupplier,
      page: () {
        final arg = Get.arguments;
        return AddSupplierScreen(
          supplier: arg is SupplierModel ? arg : null,
        );
      },
    ),
    GetPage(name: AppRoutes.purchases, page: () => const PurchaseScreen()),
    GetPage(name: AppRoutes.sales, page: () => const SalesScreen()),
    GetPage(name: AppRoutes.reports, page: () => const ReportsScreen()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
  ];
}
