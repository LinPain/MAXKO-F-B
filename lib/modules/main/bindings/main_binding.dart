import 'package:get/get.dart';

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

    if (!Get.isRegistered<AccountController>()) {
      Get.put<AccountController>(
        AccountController(),
        permanent: true,
      );
    }

    // Menu
    Get.lazyPut<MenuController>(() => MenuController());

    // Cart
    Get.put<CartController>(CartController(), permanent: true);

    Get.put<OrdersController>(OrdersController(), permanent: true);

    Get.put<NotificationsController>(
      NotificationsController(),
      permanent: true,
    );
  }
}
