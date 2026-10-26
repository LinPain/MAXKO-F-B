import 'package:get/get.dart';

import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_customization_model.dart';
import '../../cart/controllers/cart_controller.dart';

class OrdersController extends GetxController {
  OrdersController();
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
    if (currentOrder.value == null && orderHistory.isEmpty) {
      final now = DateTime.now();
      const demoItem = CartItemModel(
        productId: 'demo-matcha',
        productName: 'Trà Sữa Matcha',
        unitPrice: 42000,
        imageUrl: '',
        quantity: 2,
        customization: ProductCustomizationModel(
          sizeId: 'size-l',
          sugarLevelId: 'sugar-50',
          iceLevelId: 'ice-normal',
          toppingIds: ['topping-pearl'],
          note: '',
        ),
      );
      currentOrder.value = OrderModel(
        id: 'demo-active-order',
        orderNumber: 'MK-DEMO01',
        branchName: 'MAXKO Tea · Cầu Giấy',
        items: const [demoItem],
        subtotal: 94000,
        total: 94000,
        orderType: 'DELIVERY',
        paymentMethod: 'CASH',
        status: OrderStatus.outForDelivery,
        createdAt: now,
      );
      orderHistory.add(
        OrderModel(
          id: 'demo-completed-order',
          orderNumber: 'MK-DEMO00',
          branchName: 'Tokki Korean · Hà Nội',
          items: const [demoItem],
          subtotal: 42000,
          total: 42000,
          orderType: 'TAKEAWAY',
          paymentMethod: 'CASH',
          status: OrderStatus.completed,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      );
    }
  }

  Future<void> refreshCurrentOrder() async {
    final current = currentOrder.value;
    if (current == null || isRefreshingOrder.value) {
      return;
    }

    isRefreshingOrder.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final nextIndex = current.status.index + 1;
      if (nextIndex < OrderStatus.completed.index) {
        updateCurrentOrderStatus(OrderStatus.values[nextIndex]);
      } else {
        completeCurrentOrder();
      }
    } finally {
      isRefreshingOrder.value = false;
    }
  }

  Future<void> cancelCurrentOrder() async {
    final order = currentOrder.value;
    if (order == null) return;
    currentOrder.value = null;
    Get.snackbar(
      'Đã hủy đơn xem trước',
      'Đơn demo đã được hủy trên màn hình này.',
      snackPosition: SnackPosition.BOTTOM,
    );
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
      orderNumber: order.orderNumber,
      branchName: order.branchName,
      items: order.items,
      subtotal: order.subtotal,
      total: order.total,
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      status: status,
      createdAt: order.createdAt,
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
      orderNumber: order.orderNumber,
      branchName: order.branchName,
      items: order.items,
      subtotal: order.subtotal,
      total: order.total,
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      status: OrderStatus.completed,
      createdAt: order.createdAt,
    );

    addToHistory(completedOrder);
    clearCurrentOrder();
  }
}
