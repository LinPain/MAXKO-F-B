import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../main/controllers/main_controller.dart';

class BrandsView extends StatefulWidget {
  const BrandsView({super.key, this.homeMode = false});

  final bool homeMode;

  @override
  State<BrandsView> createState() => _BrandsViewState();
}

class _BrandsViewState extends State<BrandsView> {
  final searchController = TextEditingController();
  String selectedCategory = 'Tất cả (6)';
  String search = '';

  static const brands = <_BrandInfo>[
    _BrandInfo(
      'MAXKO Tea',
      'Trà & đồ uống',
      Icons.local_cafe_rounded,
      Color(0xFFAB2F00),
      true,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCOgKZToP8oRxSCYTDgPjfRRO1tlgR1c92QHWWCiZqYFsEtQwHTda2d1-kSp3UdxNS6LYXr2CbQkKjO5g358d5dJtBiQwxtrPnQ8NHh3oETm4YD3xEyUGupYFzuf4B-rEdkRIgwGWztEqUs1Q0G1DO66doKvcp0RdSvv2FGEum69SFC1dplRZGZRDifk84zWRYo8p6cIXFijFvFUTeQTVpGfJf5uylaRIy0sCMt9tLyR_mw7huCmk0ShA',
    ),
    _BrandInfo(
      'Tokki Korean Street Food',
      'Ẩm thực Hàn Quốc',
      Icons.ramen_dining_rounded,
      Color(0xFFDC2626),
      false,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD1i2LDsapYnoxgzN29Vmz0O3gp9_sMLL7TKheLUOH1IMSQnvT8i0mTdNiBckDQL2bvx90S-fo1QGoiF8MQceTrZwboqgrl5LJW5d_vn2WVQUSBgo4ZSQ3ZjrWqmcSio9COra35eN-IVoFU_66JHICMDrR4gMCrHEJaFgZlg0HQicLr8C5-fERwWri3yELuunAi24-Nbm4Netq9DhZBaujHGwsC9AnrJ-mCEDQuL4htiGWzPqsBmIKuvw',
    ),
    _BrandInfo(
      'Mì Cay 7 Cấp Độ',
      'Mì cay & lẩu',
      Icons.local_fire_department_rounded,
      Color(0xFFB91C1C),
      false,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAUK7pWkj06E7Gq3IoPWdgBDiodkvFmJOpLtULN0pP_i1E102Jh1g4tKR8wR6YCyIkvV8WPWTFVT0u6Hwn-RZmrYNgRo8ZSSwTkOxrObeP_jv3lGlpaMMpJ1KyYLLN_yXuqm7V5_-o0EKCvMzpcrammNzBIjhP6vuAop5psRIK9Z-bJ_wd_Y252ATkQiSbmIi1GsoThnACOvVZ2U4gbzMJEbrV1ipN8k74uCcPbfHRecnBYv2GGXx_4Ng',
    ),
    _BrandInfo(
      'Xingfu Trà Sữa',
      'Trà sữa',
      Icons.emoji_food_beverage_rounded,
      Color(0xFF7C3AED),
      false,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA0NGv731JRcmRJPppm6oNd27RKfAKh_sWtCa58opLtiAM7jokgU_yiJi3Byw0_yzLfQaoKZqWDSm3GtIHreJpWc6646-yMj9r96u0ss9o564-QYXe2c0HPxRQviug6IT52g2mv3x756HtwJLOeUlkkJrWa4D4V5JCCQQyc1ucOcpIQJ7p9mLn1FL8PAZ1hPAp18keXwaeG1IZsLUdpW5CPDpcTMXP63ia0E8vW9iusqPf3RJNTOlTZsQ',
    ),
    _BrandInfo(
      'Phở & Món Khác',
      'Món Việt',
      Icons.soup_kitchen_rounded,
      Color(0xFF15803D),
      false,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA0BdV6rzyx09VrZqdttAss7WcYL5oohOLjrmSUhdrrx1kKJVZx3E5c16y9DnA4XwdbDgA0ZYQabIf0LkLChOLcWpTu6oVMgcLheEk0HecSXbCDasquGoR27NMVb4UT0LHfbaWg0e4pldle2moEOC97b2MUDo2Vvw9BsdIW0BMVwZVvDLvLh0oDa3DIcN6GcvInyYNjEZbnNC903U9IKSgm5TYuj2UBnAEkqIPQmX-WsjsIMdLcDOYumQ',
    ),
    _BrandInfo(
      'MAXKO Bakery & Dessert',
      'Bánh & tráng miệng',
      Icons.bakery_dining_rounded,
      Color(0xFFB45309),
      false,
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBDl-hz7f8tH2uZ1HbPSLqHJBpz80Ttm6fmZ0jOy2HdUVQaA8Wqg9J2qTcbHpPfP7RASMO0fyq6mg9q4fgmllqF6yrB43K_4BosXCtB671uOfL-7FEmYES61rrXdNQrRNOaugK_CDwB0e7yWhWP1_-lhWqD-1qLZ-EzLAy3A6daRuByz8YeP9AxxKU1jva4CYoXUGiGNSA6aQ6KxAzOmmTUmeK_-YDMIxtU1aINBepjGx5LNgm7nTkyZQ',
    ),
  ];

  static const categories = [
    'Tất cả (6)',
    'Trà sữa & Trà mộc',
    'Món Hàn & Tokbokki',
    'Mì cay & Lẩu',
    'Bánh ngọt & Tráng miệng',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final visible = brands.where((brand) {
      final categoryMatches =
          selectedCategory == 'Tất cả (6)' ||
          (selectedCategory == 'Trà sữa & Trà mộc'
              ? brand.name == 'MAXKO Tea' || brand.name == 'Xingfu Trà Sữa'
              : selectedCategory == 'Món Hàn & Tokbokki'
              ? brand.name == 'Tokki Korean Street Food' ||
                    brand.name == 'Phở & Món Khác'
              : selectedCategory == 'Mì cay & Lẩu'
              ? brand.name == 'Mì Cay 7 Cấp Độ'
              : selectedCategory == 'Bánh ngọt & Tráng miệng'
              ? brand.name == 'MAXKO Bakery & Dessert'
              : true);
      return categoryMatches &&
          (query.isEmpty ||
              brand.name.toLowerCase().contains(query) ||
              brand.category.toLowerCase().contains(query));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.homeMode) ...[
            _HomeLocationCard(
              controller: searchController,
              onChanged: (value) => setState(() => search = value),
            ),
            const SizedBox(height: 10),
          ] else ...[
            const Text(
              'Khám phá MAXKO',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Thương hiệu và món ngon trong cùng một ứng dụng',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
          ],
          if (!widget.homeMode) ...[
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thương hiệu, món ăn...',
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
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
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
          const SizedBox(height: 16),
          if (widget.homeMode) ...[
            _SpotlightBanner(
              onTap: () => Get.find<MainController>().changeTab(2),
            ),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.homeMode
                      ? 'Thương hiệu thuộc MAXKO'
                      : 'Khám phá thương hiệu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${visible.length} nhãn hiệu',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          for (final brand in visible) ...[
            _BrandCard(
              brand: brand,
              onTap: brand.connected
                  ? () => Get.find<MainController>().changeTab(2)
                  : () => Get.snackbar(
                      'Sắp ra mắt',
                      '${brand.name} sẽ có mặt trên MAXKO trong thời gian tới.',
                      snackPosition: SnackPosition.BOTTOM,
                    ),
            ),
            const SizedBox(height: 12),
          ],
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Không tìm thấy thương hiệu phù hợp.')),
            ),
          if (widget.homeMode) ...[
            const SizedBox(height: 4),
            const _QualityCommitmentCard(),
            const SizedBox(height: 12),
            const _FranchiseCard(),
          ],
        ],
      ),
    );
  }
}

class _HomeLocationCard extends StatelessWidget {
  const _HomeLocationCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Flexible(child: _LocationPicker()),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm thương hiệu, món ăn...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppColors.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ],
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
            'TP. Hồ Chí Minh',
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
  const _SpotlightBanner({required this.onTap});

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
            '✦ ƯU ĐÃI THƯƠNG HIỆU NỔI BẬT',
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
          'Trà ngon mỗi ngày, ưu đãi dành riêng cho bạn.',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: _FeaturedDrink(
                image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD154_o-pGmUAYAdULQVZa23fF5qrV2vj-yYDdcd0JPkjrvsPlvsClFvrR6iLcG6gFrqU1N6Tsz29PHRVpEwAyqfBUZ0Uxewjgi5E-tZOG2SWRVPXRe8xVbdhrnsfe417F06NZStybfUNPAPaHUrrBfi5ZdR3jHNhI57uwct6KBig-Lmw64h3PfCF5aL4fGzgydIq2SZDCIhhST9Jn0UeASkYRf_6o5-HZ2Xs6gTprZyhb1y0ZM2BLVeg',
                name: 'Trà Đào Cam Sả',
                price: '39.000đ',
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _FeaturedDrink(
                image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBzHR0RCIt_6l1txkVrmZoyOolOqnhWxlJFriyb3AhkQpkck8ZhRxfcLqv8ylJrz-7ePlpY9Of79F0kplzPSDqiKyvonz1gyFEm8gH2K3PK470owqQnxQQdFzZE1qAEiIj1ucAgClSvc2r7v8Qp4c08Qp7pDWUUBSp2VPfJvzm-2Ie94Z3r0cQaVdnBlMm-XyMMK0YORb21zb5kBPeqJCIbaibLPWoIxvb0YpN2_9USlEe_kf28n7113A',
                name: 'Trà Tắc Xí Muội',
                price: '35.000đ',
              ),
            ),
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
          child: Image.network(
            image,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 38,
              height: 38,
              color: Colors.white24,
              child: const Icon(
                Icons.local_cafe_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
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
    child: Row(
      children: [
        const Expanded(
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
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
      ],
    ),
  );
}

class _BrandInfo {
  const _BrandInfo(
    this.name,
    this.category,
    this.icon,
    this.color,
    this.connected,
    this.imageUrl,
  );

  final String name;
  final String category;
  final IconData icon;
  final Color color;
  final bool connected;
  final String imageUrl;
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand, required this.onTap});

  final _BrandInfo brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(17),
                ),
                child: SizedBox(
                  height: 174,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _BrandPhotoFallback(brand: brand),
                      Image.network(
                        brand.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _BrandPhotoFallback(brand: brand),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: brand.connected
                                ? AppColors.primary
                                : AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            brand.connected ? 'ĐANG PHỤC VỤ' : 'SẮP KẾT NỐI',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: _RatingPill(),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 28, 12, 11),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC000000)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                brand.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                brand.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _BrandStat(
                            Icons.delivery_dining_rounded,
                            'Thực đơn',
                            '20 món',
                          ),
                        ),
                        const Expanded(
                          child: _BrandStat(
                            Icons.star_rounded,
                            'Đánh giá',
                            '4.9 sao',
                          ),
                        ),
                        Expanded(
                          child: _BrandStat(
                            Icons.schedule_rounded,
                            'Giờ mở cửa',
                            brand.connected ? '08–22h' : 'Sắp có',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                            ),
                            label: const Text('Xem cơ sở', maxLines: 1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.border),
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onTap,
                            icon: Icon(
                              brand.connected
                                  ? Icons.restaurant_menu_rounded
                                  : Icons.schedule_rounded,
                              size: 15,
                            ),
                            label: Text(
                              brand.connected ? 'Đặt món ngay' : 'Sắp ra mắt',
                              maxLines: 1,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: brand.connected
                                  ? AppColors.primary
                                  : const Color(0xFF1E232A),
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
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
}

class _RatingPill extends StatelessWidget {
  const _RatingPill();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 13, color: Color(0xFFB45309)),
        SizedBox(width: 2),
        Text('4.9', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _BrandStat extends StatelessWidget {
  const _BrandStat(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _BrandPhotoFallback extends StatelessWidget {
  const _BrandPhotoFallback({required this.brand});

  final _BrandInfo brand;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brand.color, AppColors.primaryDark],
      ),
    ),
    alignment: Alignment.center,
    child: Icon(brand.icon, color: Colors.white, size: 54),
  );
}
