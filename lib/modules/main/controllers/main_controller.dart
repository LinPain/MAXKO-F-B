import 'package:get/get.dart';

import '../../orders/controllers/orders_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  final isHistoryPage = false.obs;

  final isNotificationPage = false.obs;

  final isCartPage = false.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    isHistoryPage.value = false;
    isNotificationPage.value = false;
    isCartPage.value = false;
  }

  void openCart() {
    currentIndex.value = 2;
    isCartPage.value = true;
    isHistoryPage.value = false;
    isNotificationPage.value = false;
  }

  void openHistory() {
    currentIndex.value = 3;
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().loadMyOrders();
    }
    isHistoryPage.value = true;
    isNotificationPage.value = false;
    isCartPage.value = false;
  }

  void openNotifications() {
    if (Get.isRegistered<NotificationsController>()) {
      Get.find<NotificationsController>().loadNotifications();
    }
    isNotificationPage.value = true;
    isHistoryPage.value = false;
    isCartPage.value = false;
  }
}
