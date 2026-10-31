import 'package:get/get.dart';

import '../data/providers/api_client.dart';
import '../data/providers/api_provider.dart';
import '../modules/cart/controllers/cart_controller.dart';
import '../modules/main/controllers/main_controller.dart';
import '../modules/orders/controllers/orders_controller.dart';

/// Ensures routes that can be opened directly have the shared commerce state.
void ensureCommerceDependencies() {
  if (!Get.isRegistered<MainController>()) {
    Get.put<MainController>(MainController(), permanent: true);
  }
  if (!Get.isRegistered<ApiClient>()) {
    Get.put<ApiClient>(ApiProvider(baseUrl: _apiBaseUrl), permanent: true);
  }
  if (!Get.isRegistered<CartController>()) {
    Get.put<CartController>(CartController(), permanent: true);
  }
  if (!Get.isRegistered<OrdersController>()) {
    Get.put<OrdersController>(
      OrdersController(apiProvider: Get.find<ApiClient>()),
      permanent: true,
    );
  }
}

String get _apiBaseUrl {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  return 'https://api.legiapos.vn';
}

String get apiBaseUrl => _apiBaseUrl;

