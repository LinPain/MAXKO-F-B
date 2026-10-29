import 'package:get/get.dart';

import '../../../app/commerce_dependencies.dart';
import '../../../data/providers/api_client.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../controllers/payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    ensureCommerceDependencies();
    Get.lazyPut<PaymentController>(
      () => PaymentController(
        cartController: Get.find<CartController>(),
        ordersController: Get.find<OrdersController>(),
        apiProvider: Get.find<ApiClient>(),
      ),
    );
  }
}
