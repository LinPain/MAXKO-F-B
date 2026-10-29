import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/api_client.dart';
import '../../main/controllers/main_controller.dart';
import '../../../widgets/product_card.dart';

class BrandsView extends StatefulWidget {
  const BrandsView({super.key, this.homeMode = false});

  final bool homeMode;

  @override
  State<BrandsView> createState() => _BrandsViewState();
}

class _BrandsViewState extends State<BrandsView> {
  final searchController = TextEditingController();
  String selectedCategory = 'Tất cả';
  String selectedBrand = 'all';
  String search = '';

  List<String> categories = ['Tất cả'];
  List<ProductModel> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    try {
      final api = Get.find<ApiClient>();
      final categoryRes = await api.get('/api/products/categories/all');
      final productRes = await api.get('/api/products?availableOnly=true');

      final loadedCategories = <String>['Tất cả'];
      if (categoryRes is List) {
        for (final item in categoryRes) {
          final name = item is Map
              ? item['name']?.toString() ?? ''
              : item.toString();
          if (name.isNotEmpty && !loadedCategories.contains(name)) {
            loadedCategories.add(name);
          }
        }
      }

      final loadedProducts = <ProductModel>[];
      if (productRes is List) {
        for (final item in productRes) {
          if (item is Map) {
            loadedProducts.add(
              ProductModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          categories = loadedCategories;
          products = loadedProducts;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = widget.homeMode && categories.length == 1
        ? ['Tất cả', 'Trà & Đồ uống', 'Mì cay & Lẩu', 'Gà rán']
        : categories;
    final query = search.trim().toLowerCase();
    final filtered = products.where((product) {
      final categoryMatches =
          selectedCategory == 'Tất cả' || product.categoryId == selectedCategory;
      final brandMatches = !widget.homeMode ||
          selectedBrand == 'all' ||
          product.brandId == selectedBrand;
      final searchMatches = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return categoryMatches && brandMatches && searchMatches;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.homeMode) ...[
            const _HomeLocationCard(),
            const SizedBox(height: 10),
            const _FulfillmentSelector(),
            const SizedBox(height: 12),
            _BrandChipBar(
              selectedBrand: selectedBrand,
              onSelected: (value) => setState(() => selectedBrand = value),
            ),
            const SizedBox(height: 12),
            const _CouponBanner(),
            const SizedBox(height: 12),
          ] else ...[
            const Text(
              'Khám phá MAXKO',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Thực đơn & món ngon nguyên chất từ MAXKO F&B',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
          ],
          if (!widget.homeMode) ...[
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm trà, đồ uống...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoryOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categoryOptions[index];
                final label = widget.homeMode && index == 0
                    ? 'Món bán chạy'
                    : category;
                final selected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => selectedCategory = category),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceMuted,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (widget.homeMode) ...[
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.primary, size: 19),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.homeMode ? 'Món ngon nổi bật' : 'Danh sách món ăn',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${filtered.length} món',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          if (isLoading && filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Không tìm thấy sản phẩm từ máy chủ.'),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, index) {
                final product = filtered[index];
                return ProductCard(
                  product: product,
                  onTap: () => Get.toNamed(
                    AppRoutes.productDetail,
                    arguments: product,
                  ),
                );
              },
            ),
          if (widget.homeMode) ...[
            const SizedBox(height: 16),
            _ComboDealCard(product: filtered.isEmpty ? null : filtered.first),
          ],
        ],
      ),
    );
  }
}

class _HomeLocationCard extends StatelessWidget {
  const _HomeLocationCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFFFDCD2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('CỬA HÀNG PHỤC VỤ', style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .55,
                  )),
                  SizedBox(width: 4),
                  Icon(Icons.circle, color: AppColors.matcha, size: 6),
                ],
              ),
              SizedBox(height: 3),
              Text('128 Cầu Giấy, Hà Nội', style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              )),
              SizedBox(height: 2),
              Text('Cách bạn 1.5 km  •  Đang mở cửa', style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              )),
            ],
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        ),
      ],
    ),
  );
}

class _BrandChipBar extends StatelessWidget {
  const _BrandChipBar({required this.selectedBrand, required this.onSelected});

  final String selectedBrand;
  final ValueChanged<String> onSelected;

  static const items = [
    ('all', '▦  Tất cả món'),
    ('brand-legia', 'Lê Gia'),
    ('brand-tokki', 'Tokki Gà Rán'),
    ('brand-micay', 'Mì Cay 7 Cấp Độ'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 37,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = selectedBrand == item.$1;
        return ChoiceChip(
          label: Text(item.$2),
          selected: selected,
          onSelected: (_) => onSelected(item.$1),
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surfaceMuted,
          side: BorderSide.none,
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );
}

class _CouponBanner extends StatelessWidget {
  const _CouponBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFB92C00), Color(0xFFE34205)],
      ),
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.confirmation_num_outlined,
              color: Colors.white, size: 23),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MÃ ĐỘC QUYỀN HÔM NAY', style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .45,
              )),
              SizedBox(height: 2),
              Text('GIẢM 30.000đ', style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.1,
              )),
              SizedBox(height: 2),
              Text('Mã: MAXKOFIRST  ·  Đơn từ 80.000đ', style: TextStyle(
                color: Colors.white,
                fontSize: 9,
              )),
            ],
          ),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: 'MAXKOFIRST'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã sao chép mã MAXKOFIRST')),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 13),
          label: const Text('Sao chép', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 34),
          ),
        ),
      ],
    ),
  );
}

class _FulfillmentSelector extends StatelessWidget {
  const _FulfillmentSelector();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE8E5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        _FulfillmentOption(
          icon: Icons.delivery_dining_rounded,
          title: 'Giao tận nơi',
          detail: '25–30p',
          selected: true,
        ),
        const SizedBox(width: 4),
        const _FulfillmentOption(
          icon: Icons.shopping_bag_outlined,
          title: 'Mang đi',
          detail: '15p',
        ),
        const SizedBox(width: 4),
        const _FulfillmentOption(
          icon: Icons.table_restaurant_outlined,
          title: 'Ăn tại quán',
          detail: 'Chọn bàn',
        ),
      ],
    ),
  );
}

class _FulfillmentOption extends StatelessWidget {
  const _FulfillmentOption({
    required this.icon,
    required this.title,
    required this.detail,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: selected ? Colors.white : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: selected ? AppColors.primary : Colors.transparent,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 17),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.primary : AppColors.textPrimary)),
                Text(detail, maxLines: 1,
                    style: const TextStyle(fontSize: 9,
                      color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LocationPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.only(left: 11, right: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE8E5),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Hà Nội / TP.HCM',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(width: 2),
        Icon(Icons.expand_more_rounded, size: 17),
      ],
    ),
  );
}

class _SpotlightBanner extends StatelessWidget {
  const _SpotlightBanner({
    required this.featuredProducts,
    required this.onTap,
  });

  final List<ProductModel> featuredProducts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFAB2F00), Color(0xFFD53E02), Color(0xFF8B2500)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: .2),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '✦ MÓN NGON MÁY CHỦ NỔI BẬT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'MAXKO Tea',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Trà ngon đậm vị, thực đơn chính thức từ hệ thống.',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 12),
        if (featuredProducts.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < featuredProducts.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _FeaturedDrink(
                    image: featuredProducts[i].imageUrl,
                    name: featuredProducts[i].name,
                    price:
                        '${featuredProducts[i].price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ',
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                '◷ 15–25 phút   ·   ★ 4.9',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFAB2F00),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Khám phá ngay',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FeaturedDrink extends StatelessWidget {
  const _FeaturedDrink({
    required this.image,
    required this.name,
    required this.price,
  });
  final String image;
  final String name;
  final String price;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: image.isNotEmpty
              ? Image.network(
                  image,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackIcon(),
                )
              : _fallbackIcon(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _fallbackIcon() => Container(
    width: 38,
    height: 38,
    color: Colors.white24,
    child: const Icon(
      Icons.local_cafe_rounded,
      color: Colors.white,
      size: 18,
    ),
  );
}

class _ComboDealCard extends StatelessWidget {
  const _ComboDealCard({required this.product});

  final ProductModel? product;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (product?.imageUrl.isNotEmpty == true)
                Image.network(
                  product!.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _comboArtwork(),
                )
              else
                _comboArtwork(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: .04), Colors.black87],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Row(
                  children: [
                    _dealTag('COMBO TIẾT KIỆM'),
                    const SizedBox(width: 6),
                    _dealTag('GIẢM 35%'),
                  ],
                ),
              ),
              Positioned(
                left: 13,
                right: 13,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DÀNH CHO 2 NGƯỜI', style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    )),
                    const SizedBox(height: 2),
                    const Text('Combo Cặp Đôi Hỏa Diệm', style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    )),
                    Text(
                      product?.name ?? 'Mì cay bò cấp độ 1 + trà sữa trân châu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('95.000đ', style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    )),
                    Text('Tiết kiệm 50.000đ khi đặt món', style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    )),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => Get.find<MainController>().changeTab(2),
                icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                label: const Text('Chọn Combo'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _dealTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.w900,
    )),
  );

  Widget _comboArtwork() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF572B17), Color(0xFFB94B12), Color(0xFF2B1710)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(Icons.restaurant_menu_rounded,
          color: Colors.white70, size: 58),
    ),
  );
}

class _QualityCommitmentCard extends StatelessWidget {
  const _QualityCommitmentCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '◎  Cam kết chất lượng MAXKO F&B',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CommitmentItem(
                Icons.eco_outlined,
                'Nguyên liệu minh bạch',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _CommitmentItem(
                Icons.delivery_dining_rounded,
                'Giao hàng đúng hẹn',
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CommitmentItem(
                Icons.support_agent_rounded,
                'Phục vụ tận tâm',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _CommitmentItem(
                Icons.verified_outlined,
                'Đổi trả rõ ràng',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CommitmentItem extends StatelessWidget {
  const _CommitmentItem(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _FranchiseCard extends StatelessWidget {
  const _FranchiseCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF1E232A),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .12),
          blurRadius: 9,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CƠ HỘI ĐẦU TƯ 2026',
                style: TextStyle(
                  color: Color(0xFFFFB59F),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Hợp tác nhượng quyền cùng MAXKO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Đồng hành xây dựng hệ sinh thái ẩm thực Việt.',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
      ],
    ),
  );
}
