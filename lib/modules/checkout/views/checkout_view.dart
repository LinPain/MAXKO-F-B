import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_bottom_navigation.dart';

import '../../main/controllers/main_controller.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =========================
      // TOP NAVIGATION
      // =========================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppHeader(
          onNotificationTap: () {
            Get.find<MainController>().openNotifications();
          },
          onHistoryTap: () {
            Get.find<MainController>().openHistory();
          },
          onProfileTap: () {
            Get.toNamed(AppRoutes.account);
          },
        ),
      ),

      // =========================
      // CHECKOUT CONTENT
      // =========================
      body: Obx(() {
        if (controller.cartController.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              _buildCheckoutHeader(),
              const SizedBox(height: 12),

              _buildOrderTypeSection(),
              const SizedBox(height: 12),

              _buildContactSection(),
              const SizedBox(height: 12),

              _buildCartItemsSection(),
              const SizedBox(height: 12),

              _buildVoucherSection(),
              const SizedBox(height: 12),

              _buildNoteSection(),
              const SizedBox(height: 12),

              _buildSummarySection(),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),

      // =========================
      // BOTTOM ACTION + NAVIGATION
      // =========================
      bottomNavigationBar: Obx(() {
        if (controller.cartController.cartItems.isEmpty) {
          return _buildBottomNavigation();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildBottomButton(), _buildBottomNavigation()],
        );
      }),
    );
  }

  Widget _buildCheckoutHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
                SizedBox(width: 5),
                Text(
                  'Quay lại Menu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          TextButton(
            onPressed: controller.cartController.cartItems.isEmpty
                ? null
                : controller.cartController.clearCart,
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức nhận hàng',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildOrderTypeOption(
                    value: 'pickup',
                    icon: Icons.shopping_bag_outlined,
                    title: 'Mang đi',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderTypeOption(
                    value: 'dine_in',
                    icon: Icons.restaurant_outlined,
                    title: 'Tại quán',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOrderTypeOption(
                    value: 'delivery',
                    icon: Icons.delivery_dining_outlined,
                    title: 'Giao hàng',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chi nhánh nhận đơn sẽ được xác định từ hệ thống.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin nhận đơn',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.customerNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tên người nhận'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
          ),
          if (controller.selectedOrderType.value == 'delivery') ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller.deliveryAddressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
            ),
            Obx(
              () => Wrap(
                spacing: 6,
                children: [
                  ...controller.savedAddresses.map(
                    (item) => InputChip(
                      label: Text(item['label']?.toString() ?? 'Đã lưu'),
                      onPressed: () =>
                          controller.deliveryAddressController.text =
                              item['address']?.toString() ?? '',
                      onDeleted: () => controller.removeSavedAddress(item),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Lưu địa chỉ'),
                    onPressed: controller.saveDeliveryAddress,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderTypeOption({
    required String value,
    required IconData icon,
    required String title,
  }) {
    final isSelected = controller.selectedOrderType.value == value;

    return GestureDetector(
      onTap: () {
        controller.selectOrderType(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsSection() {
    return _buildCard(
      child: Column(
        children: controller.cartController.cartItems
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCartItem(item),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    final customization = item.customization;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(item.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (customization.sizeId.isNotEmpty)
                      _buildTag('Size ${customization.sizeId}'),
                    if (customization.sugarLevelId.isNotEmpty)
                      _buildTag(customization.sugarLevelId),
                    if (customization.iceLevelId.isNotEmpty)
                      _buildTag(customization.iceLevelId),
                    ...customization.toppingIds.map(
                      (topping) => _buildTag(topping),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${item.unitPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    _buildQuantityControl(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.local_cafe_outlined, color: AppColors.primary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: 64,
            height: 64,
            color: AppColors.background,
            child: const Icon(
              Icons.local_cafe_outlined,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildQuantityControl(CartItemModel item) {
    final index = controller.cartController.cartItems.indexOf(item);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: () {
              controller.cartController.updateQuantity(
                index,
                item.quantity - 1,
              );
            },
            icon: const Icon(Icons.remove, size: 15),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: () {
              controller.cartController.updateQuantity(
                index,
                item.quantity + 1,
              );
            },
            icon: const Icon(Icons.add, size: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'Mã giảm giá / Voucher',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.voucherController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã giảm giá...',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.applyVoucher,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ghi chú đơn hàng',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'VD: Giao lên tầng 3, phòng 302...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tạm tính (${controller.cartController.totalItems} món)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${controller.subtotal.toStringAsFixed(0)}đ',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${controller.total.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: Colors.white,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.continueToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến hành chọn thanh toán',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${controller.total.toStringAsFixed(0)}đ →',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: .28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Giỏ hàng đang trống',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng thêm món trước khi tiếp tục.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: Get.back, child: const Text('Quay lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AppBottomNavigation(
      selectedIndex: 2,
      orderBadgeCount: controller.cartController.totalItems,
      onSelected: (index) {
        final mainController = Get.find<MainController>();

        Get.offNamed(AppRoutes.main);

        Future.microtask(() {
          mainController.changeTab(index);
        });
      },
    );
  }
}
