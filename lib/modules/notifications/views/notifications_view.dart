import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_status.dart';
import '../../../widgets/app_header.dart';
import '../../account/controllers/account_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../orders/controllers/orders_controller.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({
    super.key,
    this.showScrollableHeader = false,
    this.scaffoldKey,
  });

  final bool showScrollableHeader;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final NotificationsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NotificationsController>();
    controller.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allNotifications = controller.notifications.toList();
      final notifications = controller.filteredNotifications;
      final activeOrder = Get.isRegistered<OrdersController>()
          ? Get.find<OrdersController>().currentOrder.value
          : null;
      return RefreshIndicator(
        onRefresh: controller.loadNotifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showScrollableHeader) _buildScrollableHeader(),
              _buildHeader(allNotifications),
              const SizedBox(height: 10),
              _buildFilterBar(allNotifications),
              if (activeOrder != null) ...[
                const SizedBox(height: 12),
                _buildActiveOrderCard(activeOrder),
              ],
              const SizedBox(height: 18),
              if (controller.isLoading.value && controller.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 38),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (controller.errorMessage.value.isNotEmpty)
                _buildErrorState(controller.errorMessage.value)
              else if (notifications.isEmpty)
                _buildEmptyState()
              else
                ..._buildGroupedCards(notifications),
              const SizedBox(height: 14),
              _buildNotificationChannels(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildScrollableHeader() {
    final main = Get.find<MainController>();
    return AppHeader(
      showNotificationAction: true,
      onMenuTap: () => widget.scaffoldKey?.currentState?.openDrawer(),
      onSearchTap: () => main.changeTab(1),
      onNotificationTap: main.openNotifications,
      onCartTap: main.openCart,
      onProfileTap: () => Get.toNamed('/account'),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> notifications) {
    final unreadCount = notifications
        .where((item) => item['isRead'] != true)
        .length;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (unreadCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$unreadCount mới',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          TextButton(
            onPressed: controller.markAllRead,
            child: const Text(
              'Đọc tất cả',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        IconButton(
          onPressed: _showFilterInfo,
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Lọc thông báo',
        ),
      ],
    );
  }

  Widget _buildFilterBar(List<Map<String, dynamic>> notifications) {
    final allCount = notifications.length;
    final orderCount = notifications
        .where((item) => item['type'] == 'order')
        .length;
    final promoCount = notifications
        .where((item) => item['type'] == 'promo')
        .length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Tất cả', 'all', allCount),
          const SizedBox(width: 8),
          _filterChip('Cập nhật đơn', 'order', orderCount),
          const SizedBox(width: 8),
          _filterChip('Ưu đãi & Voucher', 'promo', promoCount),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) => Obx(() {
    final selected = controller.selectedFilter.value == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => controller.selectedFilter.value = value,
      label: Text('$label  $count'),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceMuted,
      side: BorderSide.none,
      shape: const StadiumBorder(),
    );
  });

  List<Widget> _buildGroupedCards(List<Map<String, dynamic>> items) {
    final today = DateTime.now();
    bool isToday(Map<String, dynamic> item) {
      final date = DateTime.tryParse(item['createdAt']?.toString() ?? '');
      return date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }

    final recent = items.where(isToday).toList();
    final earlier = items.where((item) => !isToday(item)).toList();
    final widgets = <Widget>[];
    if (recent.isNotEmpty) {
      widgets.add(_sectionHeading('Hôm nay', '${recent.length} tin'));
      widgets.addAll(
        recent.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _buildNotificationCard(item),
          ),
        ),
      );
    }
    if (earlier.isNotEmpty) {
      widgets.add(_sectionHeading('Trước đây', '${earlier.length} tin'));
      widgets.addAll(
        earlier.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _buildNotificationCard(item),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _sectionHeading(String title, String count) => Padding(
    padding: const EdgeInsets.only(bottom: 9, top: 4),
    child: Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: .7,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _buildActiveOrderCard(OrderModel order) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primaryBright.withValues(alpha: .4)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .08),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.label.toString().toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  Text(
                    'Đơn hàng ${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${order.total.toStringAsFixed(0)}đ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _orderProgress(order.status),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () => Get.find<MainController>().changeTab(3),
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Theo dõi đơn hàng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _orderProgress(OrderStatus status) {
    const labels = ['Đã nhận', 'Pha chế', 'Sẵn sàng', 'Đang giao'];
    final selected = switch (status) {
      OrderStatus.submitted || OrderStatus.confirmed => 0,
      OrderStatus.preparing => 1,
      OrderStatus.ready => 2,
      OrderStatus.outForDelivery => 3,
      OrderStatus.completed || OrderStatus.cancelled => -1,
    };
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= selected;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      active ? Icons.check_rounded : Icons.circle_outlined,
                      size: 13,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (index < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotificationChannels() {
    if (!Get.isRegistered<AccountController>() ||
        !Get.find<AccountController>().isLoggedIn.value) {
      return const SizedBox.shrink();
    }
    final account = Get.find<AccountController>();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Kênh nhận thông báo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: account.loadNotificationPreferences,
                child: const Text('Làm mới'),
              ),
            ],
          ),
          _channelToggle(
            account,
            'push',
            'Thông báo ứng dụng',
            Icons.notifications_outlined,
          ),
          _channelToggle(account, 'email', 'Email', Icons.mail_outline_rounded),
          _channelToggle(account, 'sms', 'SMS', Icons.sms_outlined),
          const Text(
            'Một số kênh cần được cấu hình dịch vụ gửi trước khi hoạt động.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _channelToggle(
    AccountController account,
    String key,
    String label,
    IconData icon,
  ) => Obx(
    () => Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Switch.adaptive(
          value: account.notificationPreferences[key] ?? false,
          activeThumbColor: AppColors.primary,
          onChanged: (value) async {
            final preferences = Map<String, bool>.from(
              account.notificationPreferences,
            )..[key] = value;
            try {
              await account.updateNotificationPreferences(preferences);
            } catch (error) {
              Get.snackbar(
                'Chưa lưu được',
                error.toString().replaceFirst('Exception: ', ''),
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
        ),
      ],
    ),
  );

  void _showFilterInfo() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc thông báo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _filterChoice('Tất cả', 'all'),
            _filterChoice('Cập nhật đơn', 'order'),
            _filterChoice('Ưu đãi & Voucher', 'promo'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _filterChoice(String label, String value) => Obx(
    () => Material(
      color: Colors.transparent,
      child: ListTile(
        title: Text(label),
        trailing: controller.selectedFilter.value == value
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () {
          controller.selectedFilter.value = value;
          Get.back();
        },
      ),
    ),
  );

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isOrder = notification['type'] == 'order';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: notification['isRead'] == true
              ? AppColors.border
              : AppColors.primaryBright.withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          controller.markRead(notification);
          if (isOrder) {
            Get.find<MainController>().changeTab(3);
          } else {
            Get.snackbar(
              notification['title']?.toString() ?? '',
              notification['message']?.toString() ?? '',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification, isOrder),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title']?.toString() ?? '',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: notification['isRead'] == true
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (notification['isRead'] != true)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      notification['message']?.toString() ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          notification['timeLabel']?.toString() ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            controller.markRead(notification);
                            if (isOrder) {
                              Get.find<MainController>().changeTab(3);
                            } else {
                              Get.snackbar(
                                notification['actionLabel']?.toString() ?? '',
                                'Chức năng sẽ được kết nối với backend sau.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.primary,
                          ),
                          child: Text(
                            notification['actionLabel']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
    Map<String, dynamic> notification,
    bool isOrder,
  ) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isOrder
            ? AppColors.primary.withValues(alpha: 0.09)
            : AppColors.amber.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isOrder ? Icons.receipt_long_rounded : Icons.local_offer_rounded,
        color: isOrder ? AppColors.primary : AppColors.gold,
        size: 21,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textSecondary,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không tải được thông báo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: controller.loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Chưa có thông báo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Các thông báo về đơn hàng và ưu đãi\nsẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
