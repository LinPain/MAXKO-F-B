import 'cart_item_model.dart';
import 'order_status.dart';
import 'delivery_tracking_model.dart';

class OrderModel {
  final String id;
  final String batchId;
  final String orderNumber;
  final String branchName;
  final List<CartItemModel> items;
  final double subtotal;
  final double total;
  final String orderType;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime? createdAt;
  final DeliveryTrackingModel? deliveryTracking;

  OrderModel copyWithBatchId(String value) => OrderModel(
    id: id,
    batchId: value,
    orderNumber: orderNumber,
    branchName: branchName,
    items: items,
    subtotal: subtotal,
    total: total,
    orderType: orderType,
    paymentMethod: paymentMethod,
    status: status,
    createdAt: createdAt,
    deliveryTracking: deliveryTracking,
  );

  const OrderModel({
    required this.id,
    this.batchId = '',
    this.orderNumber = '',
    required this.branchName,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.orderType,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.deliveryTracking,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      batchId: json['batchId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      branchName: json['branchName'] ?? json['branchId'] ?? '',
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CartItemModel.fromJson)
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total:
          (json['total'] as num?)?.toDouble() ??
          (json['finalTotal'] as num?)?.toDouble() ??
          0,
      orderType: json['orderType'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      deliveryTracking: _parseDeliveryTracking(
        json['deliveryTracking'] ?? json['deliveryProgress'],
      ),
    );
  }

  static DeliveryTrackingModel? _parseDeliveryTracking(dynamic value) {
    if (value is Map) {
      return DeliveryTrackingModel.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static OrderStatus _parseStatus(dynamic value) {
    switch (value?.toString().toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERING':
        return OrderStatus.outForDelivery;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PENDING':
      case 'SUBMITTED':
      default:
        return OrderStatus.submitted;
    }
  }
}
