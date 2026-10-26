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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Đơn hàng của bạn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE3D9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        '1 đơn đang tới',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MockActiveOrderCard(onTrack: _requestLocationPermission),
                const SizedBox(height: 10),
                const _MockDeliveryPromise(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lịch sử đơn gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.snackbar(
                        'Bản xem trước',
                        'Lịch sử mẫu sẽ được thay bằng đơn hàng tài khoản của bạn.',
                      ),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const _MockHistoryOrder(
                  image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAUK7pWkj06E7Gq3IoPWdgBDiodkvFmJOpLtULN0pP_i1E102Jh1g4tKR8wR6YCyIkvV8WPWTFVT0u6Hwn-RZmrYNgRo8ZSSwTkOxrObeP_jv3lGlpaMMpJ1KyYLLN_yXuqm7V5_-o0EKCvMzpcrammNzBIjhP6vuAop5psRIK9Z-bJ_wd_Y252ATkQiSbmIi1GsoThnACOvVZ2U4gbzMJEbrV1ipN8k74uCcPbfHRecnBYv2GGXx_4Ng',
                  title: 'Mì Cay 7 Cấp Độ',
                  subtitle: 'Cơ sở Quận 1 · Hôm qua, 20:15',
                  detail: '1× Mì Cay Bò Mỹ Cấp 3  ·  1× Kimbap Chiên Xù',
                  price: '119.000đ',
                  points: '+24 điểm MAXKO',
                ),
                const SizedBox(height: 10),
                const _MockHistoryOrder(
                  image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD1i2LDsapYnoxgzN29Vmz0O3gp9_sMLL7TKheLUOH1IMSQnvT8i0mTdNiBckDQL2bvx90S-fo1QGoiF8MQceTrZwboqgrl5LJW5d_vn2WVQUSBgo4ZSQ3ZjrWqmcSio9COra35eN-IVoFU_66JHICMDrR4gMCrHEJaFgZlg0HQicLr8C5-fERwWri3yELuunAi24-Nbm4Netq9DhZBaujHGwsC9AnrJ-mCEDQuL4htiGWzPqsBmIKuvw',
                  title: 'Tokki Korean Street Food',
                  subtitle: 'Giao tận nơi · 19:40 · 24/10',
                  detail: '1× Gà sốt cay phô mai  ·  1× Trà đào',
                  price: '245.000đ',
                  points: '+32 điểm MAXKO',
                ),
                const SizedBox(height: 12),
                const _OrderHistoryFootnote(),
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

class _MockActiveOrderCard extends StatelessWidget {
  const _MockActiveOrderCard({required this.onTrack});
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3D9),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ĐANG GIAO HÀNG  ·  #MK-99214',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'MAXKO Tea · Cầu Giấy',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  Text(
                    'Cơ sở Cầu Giấy · 1,4 km',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Dự kiến giao',
                  style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
                ),
                Text(
                  '11:45',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '~12 phút nữa',
                  style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 13),
        const _DemoOrderTimeline(),
        const SizedBox(height: 12),
        const _MockMapPreview(),
        const SizedBox(height: 10),
        const _MockCourierCard(),
        const SizedBox(height: 10),
        const Text(
          'Chi tiết món (3 phần)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 5),
        const _MockOrderLine('2× Hồng Trà Sữa Nướng (M, 50% đường)', '98.000đ'),
        const SizedBox(height: 4),
        const _MockOrderLine('1× Trà Đào Cam Sả (L, ít đá)', '55.000đ'),
        const Divider(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
            const Text(
              '153.000đ',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: FilledButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.near_me_rounded, size: 17),
            label: const Text(
              'Theo dõi vị trí giao hàng',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DemoOrderTimeline extends StatelessWidget {
  const _DemoOrderTimeline();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _TimelineDot(Icons.check_rounded, 'Đã nhận', true),
      const _TimelineLine(active: true),
      _TimelineDot(Icons.coffee_rounded, 'Đang pha', true),
      const _TimelineLine(active: true),
      _TimelineDot(Icons.delivery_dining_rounded, 'Đang giao', true),
      const _TimelineLine(active: false),
      _TimelineDot(Icons.done_all_rounded, 'Hoàn tất', false),
    ],
  );
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot(this.icon, this.label, this.active);
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : AppColors.textSecondary,
          size: 14,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: active ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 7,
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ],
  );
}

class _TimelineLine extends StatelessWidget {
  const _TimelineLine({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: active ? AppColors.primary : AppColors.border,
    ),
  );
}

class _MockMapPreview extends StatelessWidget {
  const _MockMapPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 130,
        color: const Color(0xFFE5EFE7),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _DeliveryRoutePainter(hasLocation: false),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Địa chỉ giao: 26 Hoàng Quốc Việt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      'Cách 800m',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 29,
              bottom: 23,
              child: Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const Positioned(
              right: 35,
              top: 51,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.delivery_dining_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 7,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .93),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'Vị trí giao hàng mô phỏng',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockCourierCard extends StatelessWidget {
  const _MockCourierCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 21,
          backgroundColor: Color(0xFFD8D2C9),
          child: Icon(Icons.person_rounded, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nguyễn Văn Tuấn',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              Text(
                'Honda Wave · 29E1–688.22',
                style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.snackbar(
            'Bản xem trước',
            'Liên hệ tài xế sẽ khả dụng khi kết nối dịch vụ giao hàng.',
          ),
          icon: const Icon(
            Icons.call_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        IconButton(
          onPressed: () => Get.snackbar(
            'Bản xem trước',
            'Trò chuyện với tài xế sẽ sớm khả dụng.',
          ),
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
      ],
    ),
  );
}

class _MockOrderLine extends StatelessWidget {
  const _MockOrderLine(this.name, this.price);
  final String name;
  final String price;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        price,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _MockDeliveryPromise extends StatelessWidget {
  const _MockDeliveryPromise();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFE2E7F4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.verified_rounded, color: AppColors.amber, size: 19),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cam kết giao đúng giờ MAXKO · Trễ hơn 30 phút, tặng voucher.',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '1900 6868',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _MockHistoryOrder extends StatelessWidget {
  const _MockHistoryOrder({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.price,
    required this.points,
  });
  final String image;
  final String title;
  final String subtitle;
  final String detail;
  final String price;
  final String points;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                image,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 45,
                  height: 45,
                  color: AppColors.surfaceMuted,
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Đã hoàn thành',
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              points,
              style: const TextStyle(
                color: AppColors.matcha,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            OutlinedButton(
              onPressed: () => Get.snackbar(
                'Bản xem trước',
                'Đơn hàng mẫu không thể đặt lại.',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Đặt lại', style: TextStyle(fontSize: 8)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _OrderHistoryFootnote extends StatelessWidget {
  const _OrderHistoryFootnote();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Column(
      children: [
        Icon(Icons.history_rounded, color: AppColors.textSecondary),
        SizedBox(height: 5),
        Text(
          'Lịch sử 30 ngày gần đây',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 3),
        Text(
          'Đây là dữ liệu mẫu để xem trước giao diện MAXKO.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
