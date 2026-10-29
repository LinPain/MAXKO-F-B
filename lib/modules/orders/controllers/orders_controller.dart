import 'package:get/get.dart';

import '../../../data/providers/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../cart/controllers/cart_controller.dart';

class OrdersController extends GetxController {
  OrdersController({required this.apiProvider});

  final ApiClient apiProvider;
  // Current active order
  final currentOrder = Rxn<OrderModel>();

  // Previous orders
  final orderHistory = <OrderModel>[].obs;
  final isRefreshingOrder = false.obs;
  final historyError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyOrders();
  }

  Future<void> loadMyOrders() async {
    historyError.value = '';
    if (!await apiProvider.hasAccessToken()) {
      orderHistory.clear();
      return;
    }
    try {
      final response = await apiProvider.get('/api/orders/my-orders');
      final list = response is List ? response : const [];
      final orders = list
          .whereType<Map>()
          .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      orderHistory.assignAll(orders);
    } catch (error) {
      historyError.value = error.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> refreshCurrentOrder() async {
    final current = currentOrder.value;
    if (current == null || current.batchId.isEmpty || isRefreshingOrder.value) {
      return;
    }

    isRefreshingOrder.value = true;
    try {
      final response = await apiProvider.get('/api/orders/batch/${current.batchId}');
      final payload = response is Map && response['batch'] is Map
          ? response['batch'] as Map
          : response;
      final orders = payload is Map
          ? payload['orders'] ?? payload['childOrders']
          : null;
      if (orders is List && orders.isNotEmpty) {
        final matching = orders.whereType<Map>().firstWhere(
          (item) =>
              item['id']?.toString() == current.id ||
              item['_id']?.toString() == current.id,
          orElse: () => orders.first as Map,
        );
        final updatedJson = Map<String, dynamic>.from(matching);
        if ((updatedJson['items'] as List?)?.isEmpty ?? true) {
          updatedJson['items'] = current.items.map((item) => item.toJson()).toList();
        }
        final updatedOrder = OrderModel.fromJson(updatedJson).copyWithBatchId(current.batchId);
        if (updatedOrder.status == OrderStatus.completed) {
          orderHistory.insert(0, updatedOrder);
          currentOrder.value = null;
        } else {
          currentOrder.value = updatedOrder;
        }
      }
    } finally {
      isRefreshingOrder.value = false;
    }
  }

  Future<void> cancelCurrentOrder() async {
    final order = currentOrder.value;
    if (order == null) return;
    try {
      await apiProvider.patch('/api/orders/${order.id}/cancel');
      currentOrder.value = null;
      Get.snackbar(
        'Đã hủy đơn hàng',
        'Đơn ${order.orderNumber} đã được hủy thành công.',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadMyOrders();
    } catch (error) {
      Get.snackbar(
        'Không thể hủy đơn',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void reorder(OrderModel order) {
    final cart = Get.find<CartController>();
    for (final item in order.items) {
      cart.addItem(item);
    }
    Get.snackbar(
      'Đã thêm vào giỏ',
      'Các món từ đơn cũ đã được thêm cùng với món hiện có. Kiểm tra tình trạng và giá trước khi đặt.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void setCurrentOrder(OrderModel order) {
    currentOrder.value = order;
  }

  void addToHistory(OrderModel order) {
    orderHistory.insert(0, order);
  }

  void clearCurrentOrder() {
    currentOrder.value = null;
  }

  void clearHistory() {
    orderHistory.clear();
  }

  void updateCurrentOrderStatus(OrderStatus status) {
    final order = currentOrder.value;

    if (order == null) {
      return;
    }

    final updatedOrder = OrderModel(
      id: order.id,
      batchId: order.batchId,
      orderNumber: order.orderNumber,
      branchName: order.branchName,
      items: order.items,
      subtotal: order.subtotal,
      total: order.total,
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      status: status,
      createdAt: order.createdAt,
      deliveryTracking: order.deliveryTracking,
    );

    currentOrder.value = updatedOrder;

    if (status == OrderStatus.completed) {
      addToHistory(updatedOrder);
      clearCurrentOrder();
    }
  }

  void completeCurrentOrder() {
    final order = currentOrder.value;

    if (order == null) {
      return;
    }

    final completedOrder = OrderModel(
      id: order.id,
      batchId: order.batchId,
      orderNumber: order.orderNumber,
      branchName: order.branchName,
      items: order.items,
      subtotal: order.subtotal,
      total: order.total,
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      status: OrderStatus.completed,
      createdAt: order.createdAt,
      deliveryTracking: order.deliveryTracking,
    );

    addToHistory(completedOrder);
    clearCurrentOrder();
  }
}
