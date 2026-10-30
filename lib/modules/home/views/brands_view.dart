import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../widgets/product_card.dart';

class BrandsView extends StatefulWidget {
  const BrandsView({super.key});

  @override
  State<BrandsView> createState() => _BrandsViewState();
}
class _BrandsViewState extends State<BrandsView> {
  final searchController = TextEditingController();
  String selectedCategory = '';
  String search = '';

  List<String> categories = [];
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
      final categoryRes = await api.get('/api/products/categories');
      final productRes = await api.get('/api/products?availableOnly=true');

      final loadedCategories = <String>[];
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
          if (!categories.contains(selectedCategory)) selectedCategory = '';
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
    final query = search.trim().toLowerCase();
    final filtered = products.where((product) {
      final categoryMatches =
          selectedCategory.isEmpty || product.categoryId == selectedCategory;
      final searchMatches = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
              controller: searchController,
              onChanged: (value) => setState(() => search = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm',
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
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = index == 0 ? '' : categories[index - 1];
                final label = index == 0 ? 'Tất cả' : category;
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
              Expanded(
                child: Text(
                  'Sản phẩm',
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
        ],
      ),
    );
  }
}






