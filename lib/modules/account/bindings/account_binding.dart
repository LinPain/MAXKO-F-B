import 'package:get/get.dart';

import '../../../data/providers/api_client.dart';
import '../controllers/account_controller.dart';

class AccountBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AccountController>()) {
      Get.lazyPut<AccountController>(
        () => AccountController(apiProvider: Get.find<ApiClient>()),
      );
    }
  }
}
