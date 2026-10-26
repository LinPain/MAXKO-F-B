import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedFilter = 'all'.obs;

  List<Map<String, dynamic>> get filteredNotifications {
    switch (selectedFilter.value) {
      case 'order':
        return notifications.where((item) => item['type'] == 'order').toList();
      case 'promo':
        return notifications.where((item) => item['type'] == 'promo').toList();
      default:
        return notifications.toList();
    }
  }

  Future<void> loadNotifications() async {
    // NotificationsView supplies its preview list in demo mode.
    errorMessage.value = '';
    isLoading.value = false;
  }

  Future<void> markRead(Map<String, dynamic> notification) async {
    if (notification['isRead'] == true) return;
    notification['isRead'] = true;
    notifications.refresh();
  }

  Future<void> markAllRead() async {
    for (final item in notifications) {
      item['isRead'] = true;
    }
    notifications.refresh();
  }
}
