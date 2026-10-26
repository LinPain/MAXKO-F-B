import 'package:get/get.dart';

import '../../../app/commerce_dependencies.dart';
import '../../cart/controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    ensureCommerceDependencies();
    Get.lazyPut<CheckoutController>(
      () => CheckoutController(
        cartController: Get.find<CartController>(),
      ),
    );
  }
}
