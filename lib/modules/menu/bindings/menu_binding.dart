import 'package:get/get.dart';

import '../../../data/providers/api_client.dart';
import '../controllers/menu_controller.dart';
import '../../../data/repositories/product_repository.dart';

class MenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenuController>(
      () => MenuController(
        productRepository: ProductRepository(
          apiProvider: Get.find<ApiClient>(),
          brandId: 'brand-legia',
          branchId: 'b-cau-giay',
        ),
      ),
    );
  }
}
