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
  bool isLoading = true;

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
      final values = response is List
          ? response
          : response is Map && response['products'] is List
          ? response['products'] as List
          : response is Map && response['items'] is List
          ? response['items'] as List
          : const <dynamic>[];
      final loaded = values
          .whereType<Map>()
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (mounted) setState(() { products = loaded; isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = Get.find<AccountController>();
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProducts,
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
