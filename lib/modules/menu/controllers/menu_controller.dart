import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/product_model.dart';

class MenuController extends GetxController {
  static const _previewProducts = <ProductModel>[
    ProductModel(
      id: 'preview-hong-tra-nuong',
      name: 'Hồng Trà Sữa Nướng Vân Nam',
      description: 'Trà ủ ấm, caramel nướng thơm dịu.',
      price: 38000,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCOgKZToP8oRxSCYTDgPjfRRO1tlgR1c92QHWWCiZqYFsEtQwHTda2d1-kSp3UdxNS6LYxR2CbQkKjO5g358d5dJtBiQwxtrPnQ8NHh3oETm4YD3xEyUGupYFzuf4B-rEdkRIgwGWztEqUs1Q0G1DO66doKvcp0RdSvv2FGEum69SFC1dplRZGZRDifk84zWRYo8p6cIXFijFvFUTeQTVpGfJf5uylaRIy0sCMt9tLyR_mw7huCmk0ShA',
      categoryId: 'Trà sữa',
      isAvailable: true,
    ),
    ProductModel(
      id: 'preview-tra-dao-cam-sa',
      name: 'Trà Đào Cam Sả',
      description: 'Trà trái cây thanh mát cùng đào tươi.',
      price: 39000,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD154_o-pGmUAYAdULQVZa23fF5qrV2vj-yYDdcd0JPkjrvsPlvsClFvrR6iLcG6gFrqU1N6Tsz29PHRVpEwAyqfBUZ0Uxewjgi5E-tZOG2SWRVPXRe8xVbdhrnsfe417F06NZStybfUNPAPaHUrrBfi5ZdR3jHNhI57uwct6KBig-Lmw64h3PfCF5aL4fGzgydIq2SZDCIhhST9Jn0UeASkYRf_6o5-HZ2Xs6gTprZyhb1y0ZM2BLVeg',
      categoryId: 'Trà trái cây',
      isAvailable: true,
    ),
    ProductModel(
      id: 'preview-matcha-sua-tuoi',
      name: 'Matcha Sữa Tươi',
      description: 'Matcha đậm vị, sữa tươi béo nhẹ.',
      price: 42000,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA0NGv731JRcmRJPppm6oNd27RKfAKh_sWtCa58opLtiAM7jokgU_yiJi3Byw0_yzLfQaoKZqWDSm3GtIHreJpWc6646-yMj9r96u0ss9o564-QYXe2c0HPxRQviug6IT52g2mv3x756HtwJLOeUlkkJrWa4D4V5JCCQQyc1ucOcpIQJ7p9mLn1FL8PAZ1hPAp18keXwaeG1IZsLUdpW5CPDpcTMXP63ia0E8vW9iusqPf3RJNTOlTZsQ',
      categoryId: 'Trà sữa',
      isAvailable: true,
    ),
    ProductModel(
      id: 'preview-hong-tra-kem-cheese',
      name: 'Hồng Trà Kem Cheese',
      description: 'Hồng trà thơm cùng lớp kem cheese mịn.',
      price: 45000,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBDl-hz7f8tH2uZ1HbPSLqHJBpz80Ttm6fmZ0jOy2HdUVQaA8Wqg9J2qTcbHpPfP7RASMO0fyq6mg9q4fgmllqF6yrB43K_4BosXCtB671uOfL-7FEmYES61rrXdNQrRNOaugK_CDwB0e7yWhWP1_-lhWqD-1qLZ-EzLAy3A6daRuByz8YeP9AxxKU1jva4CYoXUGiGNSA6aQ6KxAzOmmTUmeK_-YDMIxtU1aINBepjGx5LNgm7nTkyZQ',
      categoryId: 'Trà',
      isAvailable: true,
    ),
  ];

  MenuController();

  List<ProductModel> get filteredProducts {
    var result = products.toList();

    // Filter by category
    if (selectedCategory.value != 'Tất cả') {
      result = result
          .where((product) => product.categoryId == selectedCategory.value)
          .toList();
    }

    // Filter by search query
    final query = searchQuery.value.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  final products = <ProductModel>[].obs;

  final categories = <String>['Tất cả', 'Trà', 'Trà sữa', 'Trà trái cây'].obs;

  final searchQuery = ''.obs;

  final selectedCategory = 'Tất cả'.obs;

  final searchController = TextEditingController();

  final isLoading = false.obs;

  final errorMessage = ''.obs;

  final isUsingMockData = false.obs;

  @override
  void onInit() {
    super.onInit();

    loadProducts();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories.assignAll([
      'Tất cả',
      'Trà',
      'Trà sữa',
      'Trà trái cây',
    ]);
    if (!categories.contains(selectedCategory.value)) {
      selectedCategory.value = 'Tất cả';
    }
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    products.assignAll(_previewProducts);
    isUsingMockData.value = true;
    isLoading.value = false;
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  void searchProducts(String value) {
    searchQuery.value = value;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
