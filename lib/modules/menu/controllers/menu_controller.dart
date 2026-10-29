import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class MenuController extends GetxController {
  MenuController({required this.productRepository});
  final ProductCatalog productRepository;
  final products = <ProductModel>[].obs;
  final categories = <String>['Tất cả'].obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'Tất cả'.obs;
  final searchController = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  List<ProductModel> get filteredProducts {
    var result = products.toList();
    if (selectedCategory.value != 'Tất cả') result = result.where((product) => product.categoryId == selectedCategory.value).toList();
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) result = result.where((product) => product.name.toLowerCase().contains(query) || product.description.toLowerCase().contains(query)).toList();
    return result;
  }

  @override
  void onInit() { super.onInit(); _loadInitialData(); }
  Future<void> _loadInitialData() async { await loadCategories(); await loadProducts(); }
  Future<void> loadCategories() async {
    try {
      final remote = await productRepository.getCategories();
      categories.assignAll(['Tất cả', ...remote]);
      if (!categories.contains(selectedCategory.value)) selectedCategory.value = 'Tất cả';
    } catch (_) { categories.assignAll(['Tất cả']); }
  }
  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try { products.assignAll(await productRepository.getProducts()); }
    catch (error) {
      products.clear();
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally { isLoading.value = false; }
  }
  void selectCategory(String category) => selectedCategory.value = category;
  void searchProducts(String value) => searchQuery.value = value;
  @override
  void onClose() { searchController.dispose(); super.onClose(); }
}
