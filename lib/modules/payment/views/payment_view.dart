import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_bottom_navigation.dart';

import '../../main/controllers/main_controller.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =========================================================
      // TOP HEADER
      // =========================================================
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

      // =========================================================
      // PAYMENT CONTENT
      // =========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentHeader(),

            const SizedBox(height: 12),

            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            _buildPaymentMethod(
              value: 'viet_qr',
              icon: Icons.qr_code_2_rounded,
              title: 'Chuyển khoản VietQR',
              subtitle: 'Sắp ra mắt — chưa kết nối ngân hàng',
              enabled: false,
            ),

            const SizedBox(height: 8),

            _buildPaymentMethod(
              value: 'ewallet',
              icon: Icons.account_balance_wallet_outlined,
              title: 'Ví MoMo / ZaloPay / ShopeePay',
              subtitle: 'Sắp ra mắt — chưa kết nối ví điện tử',
              enabled: false,
            ),

            const SizedBox(height: 8),

            _buildPaymentMethod(
              value: 'card',
              icon: Icons.credit_card_outlined,
              title: 'Thẻ ATM / Visa / Mastercard',
              subtitle: 'Sắp ra mắt — chưa kết nối cổng thanh toán',
              enabled: false,
            ),

            const SizedBox(height: 8),

            _buildPaymentMethod(
              value: 'cash',
              icon: Icons.payments_outlined,
              title: 'Tiền mặt khi nhận đồ uống',
              subtitle: 'Thanh toán tại quầy hoặc cho shipper',
            ),

            const SizedBox(height: 16),

            Obx(() {
              if (controller.selectedPaymentMethod.value != 'viet_qr') {
                return const SizedBox.shrink();
              }

              return _buildQrSection();
            }),

            const SizedBox(height: 16),

            _buildTotalSection(),

            const SizedBox(height: 12),
          ],
        ),
      ),

      // =========================================================
      // CONFIRM BUTTON + BOTTOM NAVIGATION
      // =========================================================
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildConfirmButton(), _buildBottomNavigation()],
      ),
    );
  }

  // =========================================================
  // PAYMENT HEADER
  // =========================================================

  Widget _buildPaymentHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        const Expanded(
          child: Text(
            'Thanh toán',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PAYMENT METHOD
  // =========================================================

  Widget _buildPaymentMethod({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool enabled = true,
  }) {
    return Obx(() {
      final isSelected = controller.selectedPaymentMethod.value == value;

      return GestureDetector(
        onTap: enabled ? () => controller.selectPaymentMethod(value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.35)
                  : isSelected
                  ? AppColors.primary
                  : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.35)
                      : isSelected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: !enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.35)
                    : isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
    });
  }

  // =========================================================
  // QR
  // =========================================================

  Widget _buildQrSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Mã VietQR tự động khớp nội dung',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 120,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Mã VietQR sẽ hiển thị sau khi cấu hình tài khoản ngân hàng trong backend.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TOTAL
  // =========================================================

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tổng số tiền:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    );
  }

  // =========================================================
  // CONFIRM BUTTON
  // =========================================================

  Widget _buildConfirmButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: .75)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.canConfirm ? controller.confirmOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Xác nhận đặt đơn '
                '(${controller.total.toStringAsFixed(0)}đ)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

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
