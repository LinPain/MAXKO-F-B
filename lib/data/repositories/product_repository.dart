import '../models/product_model.dart';
import '../providers/api_client.dart';

abstract interface class ProductCatalog {
  Future<List<ProductModel>> getProducts();
  Future<List<String>> getCategories();
  Future<List<Map<String, dynamic>>> getCampaigns();
}

class ProductRepository implements ProductCatalog {
  ProductRepository({
    required this.apiProvider,
    required this.brandId,
    required this.branchId,
  });

  final ApiClient apiProvider;
  final String brandId;
  final String branchId;
  final Map<String, String> _categoryNames = {};

  @override
  Future<List<ProductModel>> getProducts() async {
    final data = await apiProvider.get(
      '/api/products?brandId=$brandId&branchId=$branchId&availableOnly=true',
    );
    final products = _list(data, keys: const ['products', 'items'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    List<dynamic> groups = const [];
    try {
      groups = _list(
        await apiProvider.get('/api/modifier-groups?brandId=$brandId'),
        keys: const ['modifierGroups', 'groups', 'items'],
      );
    } catch (_) {
      // Products remain browsable if the optional modifiers route is unavailable.
    }
    final groupById = <String, Map<String, dynamic>>{
      for (final raw in groups.whereType<Map>())
        (raw['id'] ?? raw['_id'] ?? '').toString():
            Map<String, dynamic>.from(raw),
    };
    return products.map((product) {
      final ids = (product['modifierGroupIds'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const <String>[];
      final attached = product['modifierGroups'] is List
          ? (product['modifierGroups'] as List).whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)).toList()
          : ids.map((id) => groupById[id]).whereType<Map<String, dynamic>>().toList();
      final sizes = <Map<String, dynamic>>[];
      final sugar = <Map<String, dynamic>>[];
      final ice = <Map<String, dynamic>>[];
      final toppings = <Map<String, dynamic>>[];
      for (final group in attached) {
        final name = (group['name'] ?? '').toString().toLowerCase();
        final groupId = (group['id'] ?? group['_id'] ?? '').toString();
        final options = (group['options'] as List?)?.whereType<Map>() ?? const [];
        final target = name.contains('size') || name.contains('kích cỡ') || name.contains('kích thước')
            ? sizes
            : name.contains('ngọt') || name.contains('sugar')
            ? sugar
            : name.contains('đá') || name.contains('ice')
            ? ice
            : toppings;
        target.addAll(options.map((option) => {
          ...Map<String, dynamic>.from(option),
          'groupId': groupId,
          'groupName': group['name']?.toString() ?? '',
        }));
      }
      final categoryId = product['categoryId']?.toString() ?? '';
      return ProductModel.fromJson({
        ...product,
        'category': product['category'] ?? _categoryNames[categoryId] ?? categoryId,
        if (sizes.isNotEmpty) 'sizes': sizes,
        if (sugar.isNotEmpty) 'sugarLevels': sugar,
        if (ice.isNotEmpty) 'iceLevels': ice,
        if (toppings.isNotEmpty) 'toppings': toppings,
        'brandId': product['brandId'] ?? brandId,
        'branchId': branchId,
      });
    }).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    final data = await apiProvider.get(
      '/api/products/categories/all?brandId=$brandId',
    );
    final values = _list(data, keys: const ['categories', 'items']);
    _categoryNames.clear();
    for (final item in values.whereType<Map>()) {
      final id = (item['id'] ?? item['_id'] ?? item['categoryId'] ?? '').toString();
      final name = item['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) _categoryNames[id] = name;
    }
    return values
        .map((item) => item is Map ? item['name']?.toString() ?? '' : item.toString())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getCampaigns() async {
    final data = await apiProvider.get(
      '/api/customers/vouchers?brandId=$brandId',
    );
    return _list(data, keys: const ['vouchers', 'items'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<dynamic> _list(dynamic data, {required List<String> keys}) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in keys) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return const [];
  }
}

