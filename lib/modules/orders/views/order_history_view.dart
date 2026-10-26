import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../widgets/app_section_title.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/product_image.dart';
import '../controllers/orders_controller.dart';
import '../../main/controllers/main_controller.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({
    super.key,
    this.showScrollableHeader = false,
    this.scaffoldKey,
  });

  final bool showScrollableHeader;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final ordersController = Get.find<OrdersController>();

    return Obx(() {
      final orders = ordersController.orderHistory.toList();
      if (ordersController.historyError.value.isNotEmpty && orders.isEmpty) {
        return ListView(
          children: [
            if (showScrollableHeader) _buildScrollableHeader(),
            _HistoryMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Không tải được lịch sử',
              detail: ordersController.historyError.value,
              action: 'Thử lại',
              onAction: ordersController.loadMyOrders,
            ),
          ],
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: ordersController.loadMyOrders,
        child: orders.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (showScrollableHeader) _buildScrollableHeader(),
                  const SizedBox(height: 84),
                  const _HistoryMessage(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chưa có đơn hoàn tất',
                    detail: 'Các đơn hàng đã hoàn thành sẽ xuất hiện ở đây.',
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (showScrollableHeader) _buildScrollableHeader(),
                  AppSectionTitle(
                    title: 'Lịch sử đơn hàng',
                    subtitle: 'Lịch sử trải nghiệm và đơn hàng của bạn',
                    icon: Icons.receipt_long_rounded,
                    actionLabel: '${orders.length} đơn',
                  ),
                  const SizedBox(height: 14),
                  ...orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OrderCard(order: order),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildScrollableHeader() {
    final main = Get.find<MainController>();
    return AppHeader(
      onMenuTap: () => scaffoldKey?.currentState?.openDrawer(),
      onSearchTap: () => main.changeTab(1),
      onNotificationTap: main.openNotifications,
      onCartTap: main.openCart,
      onProfileTap: () => Get.toNamed('/account'),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.matcha,
                size: 18,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Đã hoàn tất',
                  style: TextStyle(
                    color: AppColors.matcha,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatDate(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.branchName.isEmpty ? 'MAXKO F&B' : order.branchName,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'Mã đơn ${order.orderNumber.isNotEmpty ? order.orderNumber : order.id} · ${order.orderType}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: order.items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: ProductImage(
                          imageUrl: item.imageUrl,
                          width: 42,
                          height: 42,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.productName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPrice(item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (order.items.length > 3) ...[
            const SizedBox(height: 5),
            Text(
              '+${order.items.length - 3} món khác',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Text(
                _formatPrice(order.total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.find<OrdersController>().reorder(order),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Đặt lại món'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Chưa có thời gian';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} · '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatPrice(double value) {
  final digits = value.round().toString();
  return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
}
