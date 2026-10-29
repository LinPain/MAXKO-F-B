import 'package:get/get.dart';

import '../../../app/commerce_dependencies.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/repositories/product_repository.dart';
import '../../account/controllers/account_controller.dart';

import '../../menu/controllers/menu_controller.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';

import '../controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MainController>()) {
      Get.put<MainController>(MainController(), permanent: true);
    }

    final baseUrl = apiBaseUrl;
    if (!Get.isRegistered<ApiClient>()) {
      Get.put<ApiClient>(ApiProvider(baseUrl: baseUrl), permanent: true);
    }

    if (!Get.isRegistered<AccountController>()) {
      Get.put<AccountController>(
        AccountController(apiProvider: Get.find<ApiClient>()),
        permanent: true,
      );
    }

    // Menu
    Get.lazyPut<ProductCatalog>(
      () => ProductRepository(
        apiProvider: Get.find<ApiClient>(),
        brandId: 'brand-legia',
        branchId: 'b-cau-giay',
      ),
    );
    Get.lazyPut<MenuController>(
      () => MenuController(productRepository: Get.find<ProductCatalog>()),
    );

    // Cart
    Get.put<CartController>(CartController(), permanent: true);

    Get.put<OrdersController>(
      OrdersController(apiProvider: Get.find<ApiClient>()),
      permanent: true,
    );

    Get.put<NotificationsController>(
      NotificationsController(apiProvider: Get.find<ApiClient>()),
      permanent: true,
    );
  }
}
