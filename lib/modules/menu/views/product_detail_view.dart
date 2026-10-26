import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/product_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_option_model.dart';
import '../controllers/product_detail_controller.dart';

class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderImage(),
                    _buildProductInformation(),
                    _buildSizeSection(),
                    _buildSugarSection(),
                    _buildIceSection(),
                    _buildToppingSection(),
                    _buildNoteSection(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 165,
          child: ProductImage(
            imageUrl: controller.product.imageUrl,
            width: double.infinity,
            height: 165,
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInformation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'MAXKO F&B GROUP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.product.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrice(controller.product.price),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SIZE
  // ------------------------------------------------------------

  Widget _buildSizeSection() {
    final options = controller.sizes;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            number: '1.',
            title: 'Chọn Size cốc',
            required: true,
          ),
          const SizedBox(height: 10),
          Obx(
            () => _buildOptionRow(
              options: options,
              selected: controller.selectedSize.value,
              onSelected: controller.selectSize,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUGAR
  // ------------------------------------------------------------

  Widget _buildSugarSection() {
    final options = controller.sugarLevels;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            number: '2.',
            title: 'Độ ngọt (Đường mía)',
            currentValue: controller.selectedSugar.value?.name,
          ),
          const SizedBox(height: 10),
          Obx(
            () => _buildChoiceRow(
              options: options,
              selected: controller.selectedSugar.value,
              onSelected: controller.selectSugar,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ICE
  // ------------------------------------------------------------

  Widget _buildIceSection() {
    final options = controller.iceLevels;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            number: '3.',
            title: 'Lượng đá / Nhiệt độ',
            currentValue: controller.selectedIce.value?.name,
          ),
          const SizedBox(height: 10),
          Obx(
            () => _buildChoiceRow(
              options: options,
              selected: controller.selectedIce.value,
              onSelected: controller.selectIce,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TOPPING
  // ------------------------------------------------------------

  Widget _buildToppingSection() {
    final options = controller.toppings;

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            number: '4.',
            title: 'Topping hấp dẫn (Tùy chọn)',
            currentValue: 'Đã chọn (${controller.selectedToppings.length})',
          ),
          const SizedBox(height: 8),
          Obx(() => Column(children: options.map(_buildToppingItem).toList())),
        ],
      ),
    );
  }

  Widget _buildToppingItem(ProductOptionModel option) {
    final selected = controller.selectedToppings.contains(option);

    return GestureDetector(
      onTap: () {
        controller.toggleTopping(option);
      },
      child: Container(
        width: double.infinity,
        height: 43,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade400,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                option.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              option.extraPrice > 0
                  ? '+${_formatPrice(option.extraPrice)}'
                  : '',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTE
  // ------------------------------------------------------------

  Widget _buildNoteSection() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5. Ghi chú cho quán (Barista)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.noteController,
            maxLines: 1,
            decoration: const InputDecoration(
              hintText: 'VD: Không lấy ống hút nhựa, cho nhiều trân châu...',
              hintStyle: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildQuantitySelector(),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: controller.isValid ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thêm vào giỏ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatPrice(controller.totalPrice),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.decreaseQuantity,
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
          Obx(
            () => Text(
              '${controller.quantity.value}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: controller.increaseQuantity,
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SHARED COMPONENTS
  // ------------------------------------------------------------

  Widget _buildSectionContainer({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: child,
    );
  }

  Widget _buildSectionTitle({
    required String number,
    required String title,
    bool required = false,
    String? currentValue,
  }) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (required)
          const Text(
            'Bắt buộc',
            style: TextStyle(fontSize: 11, color: AppColors.primary),
          )
        else if (currentValue != null)
          Text(
            currentValue,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildOptionRow({
    required List<ProductOptionModel> options,
    required ProductOptionModel? selected,
    required ValueChanged<ProductOptionModel> onSelected,
  }) {
    return Row(
      children: options.map((option) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildOptionButton(
              option: option,
              selected: selected == option,
              onTap: () {
                onSelected(option);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceRow({
    required List<ProductOptionModel> options,
    required ProductOptionModel? selected,
    required ValueChanged<ProductOptionModel> onSelected,
  }) {
    return Row(
      children: options.map((option) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 7),
            child: _buildOptionButton(
              option: option,
              selected: selected == option,
              onTap: () {
                onSelected(option);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton({
    required ProductOptionModel option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: option.isAvailable ? onTap : null,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (option.extraPrice > 0)
              Text(
                '+${_formatPrice(option.extraPrice)}',
                style: TextStyle(
                  fontSize: 9,
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)}đ';
  }

  void _addToCart() {
    controller.addToCart();
  }
}
