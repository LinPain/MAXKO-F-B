import 'package:get/get.dart';

import '../modules/cart/controllers/cart_controller.dart';
import '../modules/main/controllers/main_controller.dart';
import '../modules/orders/controllers/orders_controller.dart';

/// Ensures routes that can be opened directly have the shared commerce state.
void ensureCommerceDependencies() {
  if (!Get.isRegistered<MainController>()) {
    Get.put<MainController>(MainController(), permanent: true);
  }
  if (!Get.isRegistered<CartController>()) {
    Get.put<CartController>(CartController(), permanent: true);
  }
  if (!Get.isRegistered<OrdersController>()) {
    Get.put<OrdersController>(
      OrdersController(),
      permanent: true,
    );
  }
}

