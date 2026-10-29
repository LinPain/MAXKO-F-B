import 'package:flutter/material.dart' hide MenuController;
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../main/controllers/main_controller.dart';
import '../../../widgets/product_card.dart';
import '../controllers/menu_controller.dart';

class MenuView extends GetView<MenuController> {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            primary: true,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 7),
                      child: _StoreLocation(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _FulfillmentSelector(),
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: controller.searchProducts,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Tìm trà, topping…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: controller.searchController,
                            builder: (context, value, child) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                onPressed: () {
                                  controller.searchController.clear();
                                  controller.searchProducts('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    const _MenuOfferBanner(),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: Obx(() {
                        final categories = controller.categories.toList();
                        final selectedCategory =
                            controller.selectedCategory.value;
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = selectedCategory == category;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) =>
                                  controller.selectCategory(category),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              backgroundColor: AppColors.card,
                              selectedColor: AppColors.primaryDark,
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        final count = controller.filteredProducts.length;
                        return Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Món ngon nổi bật',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count món',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              Obx(() {
                if (controller.isLoading.value) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                if (controller.errorMessage.value.isNotEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MenuMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Chưa tải được thực đơn',
                      message: controller.errorMessage.value,
                      actionLabel: 'Thử lại',
                      onAction: controller.loadProducts,
                    ),
                  );
                }

                final products = controller.filteredProducts;
                if (products.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MenuMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Không tìm thấy món',
                      message:
                          'Thử tên món khác hoặc chọn một danh mục khác nhé.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.crossAxisExtent >= 680
                          ? 3
                          : 2;
                      return SliverGrid.builder(
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 2 ? 0.62 : 0.76,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () => Get.toNamed(
                              AppRoutes.productDetail,
                              arguments: product,
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        _CartSummaryBar(
          cart: Get.find<CartController>(),
          onOpen: () => Get.find<MainController>().openCart(),
        ),
      ],
    );
  }
}

class _StoreLocation extends StatelessWidget {
  const _StoreLocation();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: Color(0xFFFFE3D9),
          child: Icon(
            Icons.storefront_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỬA HÀNG PHỤC VỤ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chưa chọn cửa hàng',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Text(
                'Chọn cửa hàng để xem khả năng phục vụ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          ),
        ),
        Icon(Icons.expand_more_rounded),
      ],
    ),
  );
}

class _FulfillmentSelector extends StatefulWidget {
  const _FulfillmentSelector();
  @override
  State<_FulfillmentSelector> createState() => _FulfillmentSelectorState();
}

class _FulfillmentSelectorState extends State<_FulfillmentSelector> {
  int selected = 0;
  static const labels = ['Giao tận nơi', 'Mang đi', 'Ăn tại quán'];
  static const details = ['25–30p', '15p', 'Chọn bàn'];
  static const icons = [
    Icons.delivery_dining_rounded,
    Icons.shopping_bag_outlined,
    Icons.table_restaurant_outlined,
  ];

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE8E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => setState(() => selected = index),
            child: Container(
              decoration: BoxDecoration(
                color: selected == index ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icons[index],
                    size: 17,
                    color: selected == index
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: selected == index
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        details[index],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.cart, required this.onOpen});
  final CartController cart;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Obx(
    () => Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_bag_rounded,
            color: Color(0xFFFFB59F),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cart.totalItems == 0
                  ? 'Giỏ hàng đang trống'
                  : '${cart.totalItems} món · ${_price(cart.total)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton(
            onPressed: cart.totalItems == 0 ? null : onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.white24,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Xem giỏ  →',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    ),
  );

  static String _price(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
}

class _MenuMessage extends StatelessWidget {
  const _MenuMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuOfferBanner extends StatelessWidget {
  const _MenuOfferBanner();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFAB2F00), Color(0xFFD53E02)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ƯU ĐÃI THỰC ĐƠN HÔM NAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thưởng thức trà sữa & trà trái cây tươi nguyên chất',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
