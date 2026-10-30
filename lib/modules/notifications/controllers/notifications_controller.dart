import 'package:get/get.dart';
import '../../../data/providers/api_client.dart';

class NotificationsController extends GetxController {
  NotificationsController({required this.apiProvider});
  final ApiClient apiProvider;
  final notifications = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedFilter = 'all'.obs;

  List<Map<String, dynamic>> get filteredNotifications {
    switch (selectedFilter.value) {
      case 'order': return notifications.where((item) => item['type'] == 'order').toList();
      case 'promo': return notifications.where((item) => item['type'] == 'promo').toList();
      default: return notifications.toList();
    }
  }

  Future<void> loadNotifications() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await apiProvider.get('/api/notifications/inbox');
      notifications.assignAll(data is List ? data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)) : const <Map<String, dynamic>>[]);
    } catch (error) {
      notifications.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally { isLoading.value = false; }
  }

  Future<void> markRead(Map<String, dynamic> notification) async {
    if (notification['isRead'] == true) return;
    try {
      await apiProvider.patch('/api/notifications/inbox/${notification['id']}/read');
      notification['isRead'] = true;
      notifications.refresh();
    } catch (error) { errorMessage.value = error.toString().replaceFirst('Exception: ', ''); }
  }

  Future<void> markAllRead() async {
    try {
      await apiProvider.patch('/api/notifications/inbox/mark-all-read');
      for (final item in notifications) { item['isRead'] = true; }
      notifications.refresh();
    } catch (error) { errorMessage.value = error.toString().replaceFirst('Exception: ', ''); }
  }
}
