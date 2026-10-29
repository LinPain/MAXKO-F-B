import 'package:get/get.dart';

import '../../../data/providers/api_client.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(apiProvider: Get.find<ApiClient>()),
        permanent: true,
      );
    }
  }
}
