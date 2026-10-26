import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_customization_model.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/cart_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../../app/routes/app_routes.dart';

class CartView extends GetView<CartController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () {
        if (controller.cartItems.isEmpty) {
          return _buildEmptyCart();
        }

        return _buildCart();
      },
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
              size: 72,
              color: AppColors.primary.withValues(alpha: .28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Giỏ hàng đang trống',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy chọn món yêu thích và thêm vào giỏ hàng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final mainController = Get.find<MainController>();
                mainController.changeTab(2);
              },
              icon: const Icon(Icons.local_cafe_outlined),
              label: const Text('Đặt món'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.cartItems.length,
            itemBuilder: (context, index) {
              final item = controller.cartItems[index];

              return _buildCartItem(
                context,
                index,
                item,
              );
            },
          ),
        ),
        _buildBottomSummary(),
      ],
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      int index,
      CartItemModel item,
      ) {
    final customization = item.customization;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(item.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.unitPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showDeleteDialog(
                    context,
                    index,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildCustomizationDetails(
            customization,
          ),

          if (customization.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildNote(
              customization.note,
            ),
          ],

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuantitySelector(
                index,
                item.quantity,
              ),
              Text(
                '${item.totalPrice.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.local_cafe_outlined,
          color: AppColors.primary,
          size: 32,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            width: 72,
            height: 72,
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

  Widget _buildCustomizationDetails(
      ProductCustomizationModel customization,
      ) {
    final details = <String>[];

    if (customization.sizeId.isNotEmpty) {
      details.add('Size: ${customization.sizeId}');
    }

    if (customization.sugarLevelId.isNotEmpty) {
      details.add('Đường: ${customization.sugarLevelId}');
    }

    if (customization.iceLevelId.isNotEmpty) {
      details.add('Đá: ${customization.iceLevelId}');
    }

    if (customization.toppingIds.isNotEmpty) {
      details.add(
        'Topping: ${customization.toppingIds.join(', ')}',
      );
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details
            .map(
              (detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              detail,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildNote(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.edit_note_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            note,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(
      int index,
      int quantity,
      ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              controller.updateQuantity(
                index,
                quantity - 1,
              );
            },
            icon: const Icon(
              Icons.remove,
              size: 18,
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              controller.updateQuantity(
                index,
                quantity + 1,
              );
            },
            icon: const Icon(
              Icons.add,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSummaryRow(
              'Tạm tính',
              controller.subtotal,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Tổng cộng',
              controller.total,
              isTotal: true,
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.checkout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến hành chọn thanh toán',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${controller.total.toStringAsFixed(0)}đ →',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String title,
      double value, {
        bool isTotal = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight:
            isTotal ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}đ',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight:
            isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(
      BuildContext context,
      int index,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa món?'),
          content: const Text(
            'Bạn có chắc muốn xóa món này khỏi giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                controller.removeItem(index);
                Navigator.pop(context);
              },
              child: const Text(
                'Xóa',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
