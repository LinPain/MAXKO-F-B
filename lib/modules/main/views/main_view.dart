import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../cart/views/cart_view.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../home/views/brands_view.dart';
import '../../membership/views/membership_view.dart';
import '../../menu/views/menu_view.dart';
import '../../notifications/views/notifications_view.dart';
import '../../orders/views/order_history_view.dart';
import '../../orders/views/orders_view.dart';
import '../controllers/main_controller.dart';

class MainView extends GetView<MainController> {
  MainView({super.key}) : scaffoldKey = GlobalKey<ScaffoldState>();

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const BrandsView(homeMode: true),
      const BrandsView(),
      const MenuView(),
      OrdersView(showScrollableHeader: true, scaffoldKey: scaffoldKey),
      const MembershipView(),
    ];

    return Obx(() {
      final selectedIndex =
          (controller.isCartPage.value ? 2 : controller.currentIndex.value)
              .clamp(0, pages.length - 1)
              .toInt();
      final showScrollableTopBar =
          controller.isNotificationPage.value ||
          (!controller.isCartPage.value && selectedIndex == 3);
      final Widget body = controller.isNotificationPage.value
          ? NotificationsView(
              showScrollableHeader: true,
              scaffoldKey: scaffoldKey,
            )
          : controller.isCartPage.value
          ? const CartView()
          : controller.isHistoryPage.value
          ? OrderHistoryView(
              showScrollableHeader: true,
              scaffoldKey: scaffoldKey,
            )
          : pages[selectedIndex];

      return Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: _MainNavigationDrawer(controller: controller),
        appBar: showScrollableTopBar
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AppHeader(
                      onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
                      onSearchTap: () => controller.changeTab(1),
                      onNotificationTap: controller.openNotifications,
                      onCartTap: controller.openCart,
                      onProfileTap: () => Get.toNamed('/account'),
                    ),
                  ),
                ),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: body,
          ),
        ),
        bottomNavigationBar: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppBottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: controller.changeTab,
              orderBadgeCount: Get.find<CartController>().totalItems,
            ),
          ),
        ),
      );
    });
  }
}

class _MainNavigationDrawer extends StatelessWidget {
  const _MainNavigationDrawer({required this.controller});

  final MainController controller;

  @override
  Widget build(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 18, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFAB2F00), Color(0xFF7F2400)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.local_cafe_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'MAXKO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'F&B GROUP',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _DrawerItem(
                  Icons.home_outlined,
                  'Trang chủ',
                  () => _select(context, 0),
                ),
                _DrawerItem(
                  Icons.storefront_outlined,
                  'Thương hiệu',
                  () => _select(context, 1),
                ),
                _DrawerItem(
                  Icons.restaurant_menu_rounded,
                  'Đặt món',
                  () => _select(context, 2),
                ),
                _DrawerItem(
                  Icons.receipt_long_outlined,
                  'Đơn hàng',
                  () => _select(context, 3),
                ),
                _DrawerItem(
                  Icons.card_membership_outlined,
                  'Hội viên',
                  () => _select(context, 4),
                ),
                const Divider(height: 20, indent: 18, endIndent: 18),
                _DrawerItem(Icons.notifications_none_rounded, 'Thông báo', () {
                  Navigator.of(context).pop();
                  controller.openNotifications();
                }),
                _DrawerItem(Icons.person_outline_rounded, 'Tài khoản', () {
                  Navigator.of(context).pop();
                  Get.toNamed('/account');
                }),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MAXKO F&B · Phiên bản 1.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _select(BuildContext context, int index) {
    Navigator.of(context).pop();
    controller.changeTab(index);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
