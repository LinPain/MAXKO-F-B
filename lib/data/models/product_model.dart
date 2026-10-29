import 'product_option_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final bool isAvailable;
  final String brandId;
  final String branchId;

  final List<ProductOptionModel> sizes;
  final List<ProductOptionModel> sugarLevels;
  final List<ProductOptionModel> iceLevels;
  final List<ProductOptionModel> toppings;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.isAvailable,
    this.brandId = 'brand-legia',
    this.branchId = 'b-cau-giay',
    this.sizes = const [],
    this.sugarLevels = const [],
    this.iceLevels = const [],
    this.toppings = const [],
  });


  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final availability = json['branchAvailability'];
    return ProductModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ??
          (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl']?.toString() ??
          json['primaryImageUrl']?.toString() ??
          '',
      categoryId: category is Map
          ? (category['name']?.toString() ?? category['id']?.toString() ?? '')
          : category?.toString() ?? json['categoryId']?.toString() ?? '',
      isAvailable: json['isAvailable'] as bool? ??
          (availability is Map
              ? availability['isAvailable'] as bool? ?? false
              : false),
      brandId: json['brandId']?.toString() ?? 'brand-legia',
      branchId: json['branchId']?.toString() ?? 'b-cau-giay',
      sizes: _parseOptions(json['sizes']),
      sugarLevels: _parseOptions(json['sugarLevels']),
      iceLevels: _parseOptions(json['iceLevels']),
      toppings: _parseOptions(json['toppings']),
    );
  }

  static List<ProductOptionModel> _parseOptions(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(ProductOptionModel.fromJson)
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'sizes': sizes.map((e) => e.toJson()).toList(),
      'sugarLevels':
      sugarLevels.map((e) => e.toJson()).toList(),
      'iceLevels':
      iceLevels.map((e) => e.toJson()).toList(),
      'toppings':
      toppings.map((e) => e.toJson()).toList(),
    };
  }
}
