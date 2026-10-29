import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/product_image.dart';
import '../../account/controllers/account_controller.dart';
import '../../main/controllers/main_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<ProductModel> products = [];
  bool isLoading = true;
  String serviceType = 'Giao tận nơi';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await Get.find<ApiClient>().get(
        '/api/products?availableOnly=true',
      );
      if (!mounted) return;
      setState(() {
        products = response is List
            ? response
                  .whereType<Map>()
                  .map((item) => ProductModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
                  .toList()
            : [];
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: AppColors.primary,
    onRefresh: _loadProducts,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        const _HomeLocation(),
        const SizedBox(height: 9),
        _ServiceSelector(
          selected: serviceType,
          onSelected: (value) => setState(() => serviceType = value),
        ),
        const SizedBox(height: 10),
        _HeroCard(onExplore: _openMenu),
        const SizedBox(height: 9),
        const _FlashOffer(),
        const SizedBox(height: 13),
        _SectionHeading(
          title: 'Thương hiệu thành viên',
          subtitle: 'Hệ sinh thái ẩm thực đa phong cách',
          action: 'Xem tất cả',
          onTap: () => Get.find<MainController>().changeTab(1),
        ),
        const SizedBox(height: 8),
        _BrandCarousel(products: products),
        const SizedBox(height: 13),
        _SectionHeading(
          title: 'Combo Tiết Kiệm Độc Quyền',
          subtitle: 'Tiết kiệm đến 35% khi kết hợp đa chuỗi',
          action: 'Xem ưu đãi',
          onTap: _openMenu,
        ),
        const SizedBox(height: 8),
        _ComboCarousel(products: products, isLoading: isLoading),
        const SizedBox(height: 13),
        _SectionHeading(
          title: 'Cửa hàng gần bạn',
          subtitle: 'Phục vụ nhanh chóng trong bán kính 3km',
          action: 'Hà Nội  ⌄',
          onTap: () => Get.snackbar('Khu vực', 'Chọn khu vực sẽ sớm khả dụng.'),
        ),
        const SizedBox(height: 8),
        const _NearbyStores(),
        const SizedBox(height: 14),
        _SectionHeading(
          title: 'Món ngon tuyển chọn',
          subtitle: 'Top các món được yêu thích nhất hôm nay',
          action: 'Hot Deal 🔥',
          onTap: _openMenu,
        ),
        const SizedBox(height: 8),
        if (isLoading && products.isEmpty)
          const _LoadingProducts()
        else if (products.isEmpty)
          const _EmptyProducts()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: .66,
            ),
            itemBuilder: (context, index) => ProductCard(
              product: products[index],
              onTap: () => Get.toNamed(
                AppRoutes.productDetail,
                arguments: products[index],
              ),
            ),
          ),
        const SizedBox(height: 14),
        const _MembershipHighlight(),
        const SizedBox(height: 10),
        const _QualityPromise(),
      ],
    ),
  );

  void _openMenu() => Get.find<MainController>().changeTab(2);
}

class _HomeLocation extends StatelessWidget {
  const _HomeLocation();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE6DD),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on_rounded,
              color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giao đến  •  1.5 km', style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              )),
              SizedBox(height: 2),
              Text('128 Cầu Giấy, Quan Hoa, Hà Nội', style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary, size: 20),
      ],
    ),
  );
}

class _ServiceSelector extends StatelessWidget {
  const _ServiceSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const options = [
    ('Giao tận nơi', Icons.delivery_dining_rounded),
    ('Mang đi', Icons.shopping_bag_outlined),
    ('Ăn tại quán', Icons.table_restaurant_outlined),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE8E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final option in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 34,
                decoration: BoxDecoration(
                  color: selected == option.$1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(option.$2,
                        size: 14,
                        color: selected == option.$1
                            ? Colors.white
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(option.$1, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: selected == option.$1
                              ? Colors.white
                              : AppColors.textSecondary,
                        )),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFC62E00), Color(0xFF9F2600)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .17),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned(
          right: 4,
          top: 5,
          child: Icon(Icons.restaurant_rounded,
              color: Colors.white24, size: 84),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .17),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('✦  HỆ SINH THÁI ẨM THỰC MAXKO',
                style: TextStyle(color: Colors.white,
                  fontSize: 8, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 7),
            const Text('Thưởng thức trọn vẹn\nhương vị MAXKO',
              style: TextStyle(color: Colors.white,
                fontSize: 17, height: 1.08, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Đa dạng thương hiệu – Nhiều ưu đãi hấp dẫn\nĐặt món nhanh chóng, giao tận nơi tiện lợi.',
              style: TextStyle(color: Colors.white, fontSize: 9, height: 1.3),
            ),
            const Spacer(),
            Row(
              children: [
                _HeroAction(Icons.delivery_dining_rounded, 'Giao hàng'),
                const SizedBox(width: 6),
                _HeroAction(Icons.shopping_bag_outlined, 'Mang đi'),
                const SizedBox(width: 6),
                _HeroAction(Icons.table_restaurant_outlined, 'Tại quán'),
                const Spacer(),
                TextButton(
                  onPressed: onExplore,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    minimumSize: const Size(0, 29),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                  ),
                  child: const Text('Khám phá',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 12),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        )),
      ],
    ),
  );
}

class _FlashOffer extends StatefulWidget {
  const _FlashOffer();

  @override
  State<_FlashOffer> createState() => _FlashOfferState();
}

class _FlashOfferState extends State<_FlashOffer> {
  late Timer _timer;
  late Duration remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    remaining = midnight.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFD9B1)),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_fire_department_rounded,
            color: AppColors.primary, size: 20),
        const SizedBox(width: 6),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GIỜ VÀNG GIÁ SỐC', style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              )),
              Text('Giảm đến 35% cho combo hôm nay',
                  style: TextStyle(fontSize: 8)),
            ],
          ),
        ),
        _CountdownBox(value: _twoDigits(remaining.inHours), label: 'giờ'),
        const SizedBox(width: 3),
        _CountdownBox(value: _twoDigits(remaining.inMinutes % 60), label: 'phút'),
        const SizedBox(width: 5),
        TextButton(
          onPressed: () => Get.find<MainController>().changeTab(2),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            minimumSize: const Size(0, 29),
          ),
          child: const Text('SĂN NGAY ›',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text('$value $label', style: const TextStyle(
      fontSize: 7,
      fontWeight: FontWeight.w800,
    )),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
            )),
            Text(subtitle, style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
            )),
          ],
        ),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text(action, style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
        )),
      ),
    ],
  );
}

class _BrandCarousel extends StatelessWidget {
  const _BrandCarousel({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final brands = [
      ('brand-legia', 'Hồng Trà Lê Gia', 'Trà sữa truyền thống'),
      ('brand-tokki', 'Tokki – Korean Street Food', 'Gà rán sốt cay'),
      ('brand-micay', 'Mì Cay 7 Cấp Độ', 'Mì cay chuẩn vị Hàn'),
    ];
    return SizedBox(
      height: 145,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final brand = brands[index];
          final product = products.cast<ProductModel?>().firstWhere(
            (item) => item?.brandId == brand.$1,
            orElse: () => products.isEmpty ? null : products[index % products.length],
          );
          return Container(
            width: 205,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (product != null)
                        ProductImage(imageUrl: product.imageUrl,
                            width: 205, height: 90)
                      else
                        const _ImagePlaceholder(icon: Icons.storefront_rounded),
                      Positioned(
                        left: 7,
                        bottom: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('★ 4.9', style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brand.$2, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9,
                          fontWeight: FontWeight.w900)),
                      Text(brand.$3, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8,
                          color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComboCarousel extends StatelessWidget {
  const _ComboCarousel({required this.products, required this.isLoading});
  final List<ProductModel> products;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(isLoading ? 'Đang tải ưu đãi…' : 'Ưu đãi sẽ sớm được cập nhật',
            style: const TextStyle(fontSize: 10,
                color: AppColors.textSecondary)),
      );
    }
    final items = products.take(3).toList();
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _ComboCard(product: items[index]),
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  const _ComboCard({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) => Container(
    width: 270,
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: ProductImage(imageUrl: product.imageUrl,
              width: 94, height: 106),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('COMBO ĐẶC BIỆT', style: TextStyle(
                color: AppColors.primary,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              )),
              const SizedBox(height: 3),
              Text(product.name, maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              const Text('Tiết kiệm 35% khi kết hợp',
                style: TextStyle(fontSize: 7,
                    color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text(_formatPrice(product.price),
                    style: const TextStyle(color: AppColors.primary,
                      fontSize: 12, fontWeight: FontWeight.w900))),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Get.toNamed(AppRoutes.productDetail,
                        arguments: product),
                    icon: const Icon(Icons.add_circle_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NearbyStores extends StatelessWidget {
  const _NearbyStores();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _StoreRow(
        icon: Icons.local_cafe_rounded,
        name: 'Xingfu Trà Sữa – Cầu Giấy',
        distance: '1.2 km',
        meta: '4.8  •  Mở cửa',
      ),
      SizedBox(height: 6),
      _StoreRow(
        icon: Icons.ramen_dining_rounded,
        name: 'Mì Cay 7 Cấp Độ – Trần Thái Tông',
        distance: '2.3 km',
        meta: '4.7  •  Mở cửa',
      ),
    ],
  );
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.icon,
    required this.name,
    required this.distance,
    required this.meta,
  });

  final IconData icon;
  final String name;
  final String distance;
  final String meta;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w800)),
              Text('$distance  •  $meta', style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 7,
              )),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary, size: 18),
      ],
    ),
  );
}

class _MembershipHighlight extends StatelessWidget {
  const _MembershipHighlight();

  @override
  Widget build(BuildContext context) {
    final account = Get.find<AccountController>();
    return Obx(() => Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B3E0A), Color(0xFF4C2109)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD186), size: 16),
              const SizedBox(width: 5),
              const Expanded(child: Text('HỘI VIÊN MAXKO CLUB',
                style: TextStyle(color: Colors.white,
                  fontSize: 9, fontWeight: FontWeight.w900))),
              Text(account.membershipTierLabel,
                style: const TextStyle(color: Color(0xFFFFD186),
                  fontSize: 8, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text(account.isLoggedIn.value ? account.username.value : 'Tham gia MAXKO Club',
            style: const TextStyle(color: Colors.white,
              fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Row(
            children: [
              const Expanded(child: Text('Điểm khả dụng',
                style: TextStyle(color: Colors.white70, fontSize: 8))),
              Text('${account.loyaltyPoints.value}',
                style: const TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              const Text('điểm', style: TextStyle(color: Colors.white70,
                  fontSize: 8)),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Get.find<MainController>().changeTab(4),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                ),
                child: const Text('Quét mã', style: TextStyle(fontSize: 8)),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _QualityPromise extends StatelessWidget {
  const _QualityPromise();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('Cam kết dịch vụ MAXKO F&B',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900))),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _PromiseTile(Icons.verified_outlined,
                'Nguyên liệu minh bạch')),
            SizedBox(width: 6),
            Expanded(child: _PromiseTile(Icons.delivery_dining_rounded,
                'Giao nhanh 25 phút')),
          ],
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _PromiseTile(Icons.receipt_long_rounded,
                'Tích điểm chung')),
            SizedBox(width: 6),
            Expanded(child: _PromiseTile(Icons.support_agent_rounded,
                'Đổi trả linh hoạt')),
          ],
        ),
      ],
    ),
  );
}

class _PromiseTile extends StatelessWidget {
  const _PromiseTile(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 13),
        const SizedBox(width: 5),
        Expanded(child: Text(label, style: const TextStyle(
          fontSize: 7, fontWeight: FontWeight.w700,
        ))),
      ],
    ),
  );
}

class _LoadingProducts extends StatelessWidget {
  const _LoadingProducts();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      children: [
        Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 24),
        SizedBox(width: 9),
        Expanded(child: Text('Thực đơn đang được cập nhật.',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
      ],
    ),
  );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceMuted,
    child: Icon(icon, color: AppColors.primary.withValues(alpha: .55), size: 32),
  );
}

String _formatPrice(double value) =>
    '${value.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';
