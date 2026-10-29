import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../../../app/theme/app_colors.dart';
import '../../../widgets/app_header.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../data/models/delivery_tracking_model.dart';
import '../controllers/orders_controller.dart';
import '../../main/controllers/main_controller.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({
    super.key,
    this.showScrollableHeader = false,
    this.scaffoldKey,
  });

  final bool showScrollableHeader;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  final selectedRating = 0.obs;
  final reviewController = TextEditingController();

  OrderModel? get order {
    return Get.find<OrdersController>().currentOrder.value;
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.find<OrdersController>();

    return Obx(() {
      final currentOrder = ordersController.currentOrder.value;

      if (currentOrder == null) {
        return _buildEmptyOrder();
      }

      return RefreshIndicator(
        onRefresh: ordersController.refreshCurrentOrder,
        child: CustomScrollView(
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (widget.showScrollableHeader) _buildScrollableHeader(),
                    if (widget.showScrollableHeader) const SizedBox(height: 4),
                    _buildStatusCard(),
                    if (currentOrder.status == OrderStatus.submitted ||
                        currentOrder.status == OrderStatus.confirmed)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: ordersController.cancelCurrentOrder,
                          icon: const Icon(Icons.close),
                          label: const Text('Hủy đơn'),
                        ),
                      ),
                    if (_isDeliveryOrder(currentOrder)) ...[
                      const SizedBox(height: 12),
                      _buildDeliveryTrackingCard(currentOrder.deliveryTracking),
                    ],
                    const SizedBox(height: 12),
                    _buildPosCard(),
                    const SizedBox(height: 12),
                    _buildOrderDetails(),
                    const SizedBox(height: 12),
                    _buildReviewSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyOrder() {
    final ordersController = Get.find<OrdersController>();
    return CustomScrollView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showScrollableHeader) _buildScrollableHeader(),
                if (widget.showScrollableHeader) const SizedBox(height: 4),
                const Text('Đơn hàng của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 10),
                      const Text('Bạn chưa có đơn hàng đang hoạt động.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(ordersController.historyError.value.isNotEmpty ? ordersController.historyError.value : 'Đơn hàng sẽ xuất hiện tại đây sau khi bạn đặt món.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableHeader() {
    final main = Get.find<MainController>();
    return AppHeader(
      onMenuTap: () => widget.scaffoldKey?.currentState?.openDrawer(),
      onSearchTap: () => main.changeTab(1),
      onNotificationTap: main.openNotifications,
      onCartTap: main.openCart,
      onProfileTap: () => Get.toNamed('/account'),
    );
  }

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------

  Widget _buildStatusCard() {
    final currentOrder = order!;
    final displayNumber = currentOrder.orderNumber.isNotEmpty
        ? currentOrder.orderNumber
        : currentOrder.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayNumber.startsWith('#')
                      ? displayNumber
                      : '#$displayNumber',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildOrderTypeBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentOrder.status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (currentOrder.branchName.isNotEmpty)
            Text(
              'Cửa hàng: ${currentOrder.branchName}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          const SizedBox(height: 22),
          _buildStatusTimeline(),
        ],
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      String message;
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        message = 'Đã cấp quyền vị trí. Theo dõi trực tiếp sẽ hoạt động khi có API giao hàng.';
      } else if (permission == LocationPermission.deniedForever) {
        if (kIsWeb) {
          message = 'Quyền vị trí đã bị chặn. Hãy bật quyền Location trong cài đặt trang của trình duyệt.';
        } else {
          message = 'Quyền vị trí bị chặn. Hãy bật quyền Location trong cài đặt ứng dụng.';
          if (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS) {
            await Geolocator.openAppSettings();
          }
        }
      } else {
        message = 'Bạn chưa cấp quyền vị trí. Bạn có thể cho phép sau.';
      }
      Get.snackbar(
        'Quyền vị trí',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Quyền vị trí',
        'Không thể yêu cầu quyền vị trí trên nền tảng này.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool _isDeliveryOrder(OrderModel order) =>
      order.orderType.toUpperCase() == 'DELIVERY';

  Widget _buildDeliveryTrackingCard(DeliveryTrackingModel? tracking) {
    final hasLocation = tracking?.hasCourierLocation ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Theo dõi giao hàng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasLocation ? 'GPS' : 'Sẵn sàng kết nối',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DeliveryRoutePainter(hasLocation: hasLocation),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 20,
                  child: _mapPin(Icons.storefront_rounded, AppColors.primary),
                ),
                Positioned(
                  right: 24,
                  bottom: 18,
                  child: _mapPin(
                    Icons.location_on_rounded,
                    hasLocation ? Colors.green : AppColors.textSecondary,
                  ),
                ),
                if (hasLocation)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 51,
                    child: Center(
                      child: _mapPin(
                        Icons.delivery_dining_rounded,
                        Colors.deepOrange,
                      ),
                    ),
                  ),
                if (!hasLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Bản đồ sẽ hiển thị khi kết nối API GPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (hasLocation) ...[
            if (tracking?.courierName?.isNotEmpty == true)
              Text(
                'Tài xế: ${tracking!.courierName}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            Text(
              'Vị trí: ${tracking!.latitude!.toStringAsFixed(5)}, ${tracking.longitude!.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            if (tracking.etaMinutes != null)
              Text(
                'Dự kiến còn ${tracking.etaMinutes} phút',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            if (tracking.updatedAt != null)
              Text(
                'Cập nhật lúc ${TimeOfDay.fromDateTime(tracking.updatedAt!.toLocal()).format(context)}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
          ] else
            const Text(
              'Đơn giao hàng đã sẵn sàng cho tính năng theo dõi vị trí. Chưa có dữ liệu GPS trực tiếp.',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _requestLocationPermission,
              icon: const Icon(Icons.my_location_rounded, size: 16),
              label: const Text('Cho phép vị trí'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPin(IconData icon, Color color) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 5),
      ],
    ),
    child: Icon(icon, color: color, size: 18),
  );

  Widget _buildOrderTypeBadge() {
    final currentOrder = order!;
    if (currentOrder.orderType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        currentOrder.orderType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final statuses = OrderStatus.values
        .where((status) => status != OrderStatus.cancelled)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final completed = _isStatusCompleted(status);

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: completed
                            ? AppColors.primaryBright
                            : Colors.white24,
                      ),
                    ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? AppColors.primaryBright
                          : Colors.white12,
                      border: Border.all(
                        color: completed
                            ? AppColors.primaryBright
                            : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: completed ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _isStatusCompleted(statuses[index + 1])
                            ? Colors.orange
                            : Colors.white24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                status.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: completed ? Colors.orange : Colors.white54,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  bool _isStatusCompleted(OrderStatus status) {
    final currentOrder = order!;
    if (currentOrder.status == OrderStatus.cancelled) return false;
    return currentOrder.status.index >= status.index;
  }

  // ------------------------------------------------------------
  // POS
  // ------------------------------------------------------------

  Widget _buildPosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🖥 Muốn xem đơn này trên máy POS quầy?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Thông tin đơn hàng có thể được đồng bộ với hệ thống POS.',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Get.snackbar(
                'POS',
                'Chức năng đồng bộ POS sẽ được xây dựng sau.',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Xem trên POS →', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ORDER DETAILS
  // ------------------------------------------------------------

  Widget _buildOrderDetails() {
    final currentOrder = order!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết đồ uống',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...currentOrder.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _buildCustomizationText(item),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          _buildPriceRow('Tạm tính', currentOrder.subtotal),

          const SizedBox(height: 8),

          _buildPriceRow('Tổng cộng', currentOrder.total, isTotal: true),
        ],
      ),
    );
  }

  String _buildCustomizationText(CartItemModel item) {
    final customization = item.customization;

    final values = <String>[];

    if (customization.sizeId.isNotEmpty) {
      values.add(_formatOption(customization.sizeId));
    }

    if (customization.sugarLevelId.isNotEmpty) {
      values.add(_formatOption(customization.sugarLevelId));
    }

    if (customization.iceLevelId.isNotEmpty) {
      values.add(_formatOption(customization.iceLevelId));
    }

    for (final toppingId in customization.toppingIds) {
      values.add(_formatOption(toppingId));
    }

    return values.join(' • ');
  }

  String _formatOption(String value) {
    switch (value) {
      case 'size-s':
        return 'Size S';
      case 'size-m':
        return 'Size M';
      case 'size-l':
        return 'Size L';

      case 'sugar-30':
        return '30% đường';
      case 'sugar-50':
        return '50% đường';
      case 'sugar-70':
        return '70% đường';
      case 'sugar-100':
        return '100% đường';

      case 'ice-none':
        return 'Không đá';
      case 'ice-less':
        return 'Ít đá';
      case 'ice-normal':
        return 'Đá bình thường';
      case 'ice-more':
        return 'Nhiều đá';

      case 'topping-pearl':
        return 'Trân châu';
      case 'topping-cheese':
        return 'Kem cheese';
      case 'topping-pudding':
        return 'Pudding';

      default:
        return value;
    }
  }

  Widget _buildPriceRow(String title, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}đ',
          style: TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REVIEW
  // ------------------------------------------------------------

  Widget _buildReviewSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 18),
              SizedBox(width: 5),
              Text(
                'Đánh giá chất lượng phục vụ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final selected = selectedRating.value >= rating;

                return IconButton(
                  onPressed: () {
                    selectedRating.value = rating;
                  },
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Chia sẻ cảm nhận về hương vị, topping, đá, đường...',
              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Gửi nhận xét',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReview() {
    if (selectedRating.value == 0) {
      Get.snackbar(
        'Đánh giá',
        'Vui lòng chọn số sao.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Đánh giá',
      'Đánh giá sẽ được gửi lên backend ở bước tích hợp API.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _DeliveryRoutePainter extends CustomPainter {
  const _DeliveryRoutePainter({required this.hasLocation});
  final bool hasLocation;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCB9A8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(42, 35)
      ..cubicTo(
        size.width * 0.32,
        30,
        size.width * 0.60,
        size.height - 30,
        size.width - 42,
        size.height - 36,
      );
    canvas.drawPath(path, paint);
    if (!hasLocation) {
      final dotPaint = Paint()..color = const Color(0xFFCCB9A8);
      for (var i = 0; i < 7; i++) {
        canvas.drawCircle(_pointOnRoute(size, (i + 1) / 8), 2.2, dotPaint);
      }
    }
  }

  Offset _pointOnRoute(Size size, double t) {
    final start = Offset(42, 35),
        end = Offset(size.width - 42, size.height - 36);
    final control1 = Offset(size.width * 0.32, 30),
        control2 = Offset(size.width * 0.60, size.height - 30);
    final oneMinus = 1 - t;
    return Offset(
      oneMinus * oneMinus * oneMinus * start.dx +
          3 * oneMinus * oneMinus * t * control1.dx +
          3 * oneMinus * t * t * control2.dx +
          t * t * t * end.dx,
      oneMinus * oneMinus * oneMinus * start.dy +
          3 * oneMinus * oneMinus * t * control1.dy +
          3 * oneMinus * t * t * control2.dy +
          t * t * t * end.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _DeliveryRoutePainter oldDelegate) =>
      oldDelegate.hasLocation != hasLocation;
}

