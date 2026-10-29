import 'dart:math';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../orders/controllers/orders_controller.dart';

class PaymentController extends GetxController {
  final CartController cartController;
  final OrdersController ordersController;
  final ApiClient apiProvider;

  PaymentController({
    required this.cartController,
    required this.ordersController,
    required this.apiProvider,
  });

  final selectedPaymentMethod = 'cash'.obs;

  final isSubmitting = false.obs;
  String? _checkoutIdempotencyKey;
  late final Map<String, dynamic> checkout = Map<String, dynamic>.from(
    Get.arguments as Map? ?? {},
  );

  double get total =>
      (checkout['total'] as num?)?.toDouble() ?? cartController.total;

  bool get canConfirm {
    return selectedPaymentMethod.value == 'cash' &&
        cartController.cartItems.isNotEmpty;
  }

  void selectPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }

  Future<void> confirmOrder() async {
    if (isSubmitting.value) return;
    if (cartController.cartItems.isEmpty) {
      Get.snackbar(
        'Giỏ hàng trống',
        'Không thể tạo đơn hàng khi giỏ hàng đang trống.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedPaymentMethod.value.isEmpty) {
      Get.snackbar(
        'Chưa chọn phương thức',
        'Vui lòng chọn phương thức thanh toán.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (selectedPaymentMethod.value != 'cash') {
      Get.snackbar(
        'Thanh toán chưa khả dụng',
        'Hiện chỉ hỗ trợ tiền mặt khi nhận đơn.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final secureRandom = Random.secure();
      _checkoutIdempotencyKey ??= List<int>.generate(
        32,
        (_) => secureRandom.nextInt(256),
      ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
      const method = 'CASH';
      final now = DateTime.now();
      final groups = <String, List<dynamic>>{};
      final branchIds = checkout['branchIdsByBrand'] is Map
          ? Map<String, dynamic>.from(checkout['branchIdsByBrand'] as Map)
          : const <String, dynamic>{};
      for (final item in cartController.cartItems) {
        final branchId = branchIds[item.brandId]?.toString() ?? item.branchId;
        final groupKey = '$branchId|${item.brandId}';
        groups.putIfAbsent(groupKey, () => []).add(item);
      }
      var groupIndex = 0;
      final groupedOrders = groups.entries.map((entry) {
        final isDelivery = checkout['orderType']?.toString() == 'DELIVERY';
        final deliveryShippingFee = isDelivery && groupIndex == 0
            ? (checkout['deliveryFee'] as num?)?.toDouble() ?? 15000
            : 0;
        groupIndex++;
        final ids = entry.key.split('|');
        final items = entry.value;
        return {
          'branchId': ids.first,
          'brandId': ids.length > 1 ? ids[1] : 'brand-legia',
          'shippingFee': deliveryShippingFee,
          'items': items
              .map(
                (item) => {
                  'productId': item.productId,
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'totalPrice': item.totalPrice,
                  'selectedModifiers': item.customization.selectedModifiers,
                },
              )
              .toList(),
        };
      }).toList();
      final result = await apiProvider.post(
        '/api/orders/batch-checkout',
        body: {
          'customerPhone': checkout['customerPhone']?.toString() ?? '',
          'customerName': checkout['customerName']?.toString() ?? '',
          'orderType': checkout['orderType']?.toString() ?? 'TAKEAWAY',
          'channel': 'APP',
          'deliveryAddress': checkout['deliveryAddress']?.toString() ?? '',
          'note': checkout['note']?.toString() ?? '',
          'voucherCode': checkout['voucherCode']?.toString() ?? '',
          if (checkout['deliveryCoordinates'] is Map)
            'deliveryCoordinates': checkout['deliveryCoordinates'],
          'paymentMethod': method,
          'idempotencyKey': _checkoutIdempotencyKey,
          'groupedOrders': groupedOrders,
        },
      );
      final payload = result is Map && result['batch'] is Map
          ? result['batch'] as Map
          : result;
      final batchId = payload is Map
          ? payload['batchId']?.toString() ?? payload['id']?.toString() ?? ''
          : '';
      final serverOrders = payload is Map
          ? payload['orders'] ?? payload['childOrders']
          : null;
      final firstServerOrder =
          serverOrders is List &&
              serverOrders.isNotEmpty &&
              serverOrders.first is Map
          ? Map<String, dynamic>.from(serverOrders.first as Map)
          : <String, dynamic>{};
      final parsedOrder = firstServerOrder.isNotEmpty
          ? OrderModel.fromJson(firstServerOrder)
          : null;
      final orderCode = batchId.isNotEmpty
          ? batchId
          : now.millisecondsSinceEpoch.toRadixString(36).toUpperCase();
      final order = OrderModel(
        id: parsedOrder?.id.isNotEmpty == true ? parsedOrder!.id : orderCode,
        batchId: batchId,
        orderNumber: parsedOrder?.orderNumber ?? 'MK-$orderCode',
        branchName: parsedOrder?.branchName ?? 'MAXKO F&B',
        items: parsedOrder?.items.isNotEmpty == true
            ? parsedOrder!.items
            : List.from(cartController.cartItems),
        subtotal: parsedOrder?.subtotal ?? cartController.subtotal,
        total: parsedOrder?.total ?? total,
        orderType: checkout['orderType']?.toString() ?? 'TAKEAWAY',
        paymentMethod: method,
        status: parsedOrder?.status ?? OrderStatus.submitted,
        createdAt: parsedOrder?.createdAt ?? now,
      );
      ordersController.setCurrentOrder(order);
      _checkoutIdempotencyKey = null;
      cartController.clearCart();
      Get.snackbar(
        'Đã xác nhận đơn',
        'Đơn ${order.orderNumber} đã được gửi tới MAXKO.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(AppRoutes.main);
      Future.microtask(() => Get.find<MainController>().changeTab(3));
    } catch (error) {
      Get.snackbar(
        'Không thể tạo đơn hàng',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}

