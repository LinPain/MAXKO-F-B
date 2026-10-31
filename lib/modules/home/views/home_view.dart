import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../widgets/product_card.dart';
import '../../account/controllers/account_controller.dart';
import '../../main/controllers/main_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<ProductModel> products = [];
  List<Map<String, dynamic>> promotions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final api = Get.find<ApiClient>();
    final responses = await Future.wait<dynamic>([
      api.get('/api/products?availableOnly=true').then((value) => value).catchError((_) => null),
      api.get('/api/promotions?brandId=brand-legia').then((value) => value).catchError((_) => null),
    ]);

    if (!mounted) return;
    final productValues = _listFromResponse(responses[0]);
    final promotionValues = _listFromResponse(responses[1]);
    setState(() {
      if (responses[0] != null) {
        products = productValues
            .whereType<Map>()
            .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      if (responses[1] != null) {
        promotions = promotionValues
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      isLoading = false;
    });
  }

  List<dynamic> _listFromResponse(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['promotions'] is List) {
      return response['promotions'] as List;
    }
    if (response is Map && response['products'] is List) {
      return response['products'] as List;
    }
    if (response is Map && response['items'] is List) {
      return response['items'] as List;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final account = Get.find<AccountController>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHomeData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          Obx(() {
            final address = account.savedAddresses.isEmpty
                ? ''
                : account.savedAddresses.first['address']?.toString() ?? '';
            if (address.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SavedAddressCard(address: address),
            );
          }),
          if (promotions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Ưu đãi đang diễn ra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: promotions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _PromotionCard(
                  promotion: promotions[index],
                  onTap: () => Get.find<MainController>().changeTab(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sản phẩm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => Get.find<MainController>().changeTab(2),
                child: const Text('Xem thực đơn'),
              ),
            ],
          ),
          if (isLoading && products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (products.isNotEmpty)
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
          if (account.isLoggedIn.value) ...[
            const SizedBox(height: 14),
            Obx(() => _MembershipSummary(
                  tier: account.membershipTierLabel,
                  points: account.loyaltyPoints.value,
                )),
          ],
        ],
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion, required this.onTap});

  final Map<String, dynamic> promotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = promotion['type']?.toString().toUpperCase();
    final value = (promotion['value'] as num?)?.toDouble() ?? 0;
    final discount = type == 'PERCENT'
        ? 'Giảm ${value.toStringAsFixed(0)}%'
        : 'Giảm ${value.toStringAsFixed(0)}đ';
    final code = promotion['code']?.toString() ?? '';

    return SizedBox(
      width: 280,
      child: Material(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, color: Colors.white, size: 18),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        discount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  promotion['title']?.toString() ?? 'Ưu đãi MAXKO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    promotion['description']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Row(
                  children: [
                    if (code.isNotEmpty)
                      Expanded(
                        child: Text(
                          'Mã: $code',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    const Text('Chọn món  ›', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembershipSummary extends StatelessWidget {
  const _MembershipSummary({required this.tier, required this.points});

  final String tier;
  final int points;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(tier)),
            Text('$points điểm'),
          ],
        ),
      );
}
