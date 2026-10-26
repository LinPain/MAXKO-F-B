import '../models/product_model.dart';

/// Local catalog used by the app while the backend is disconnected.
abstract interface class ProductCatalog {
  Future<List<ProductModel>> getProducts();
  Future<List<String>> getCategories();
  Future<List<Map<String, dynamic>>> getCampaigns();
}

class ProductRepository implements ProductCatalog {
  const ProductRepository();

  static const _products = <ProductModel>[
    ProductModel(
      id: 'demo-peach-tea',
      name: 'Trà Đào Cam Sả',
      description: 'Trà đào thanh mát kết hợp cam và sả.',
      price: 39000,
      imageUrl: '',
      categoryId: 'Trà trái cây',
      isAvailable: true,
    ),
    ProductModel(
      id: 'demo-matcha-milk-tea',
      name: 'Trà Sữa Matcha',
      description: 'Trà sữa matcha thơm đậm vị.',
      price: 42000,
      imageUrl: '',
      categoryId: 'Trà sữa',
      isAvailable: true,
    ),
    ProductModel(
      id: 'demo-cheese-tea',
      name: 'Hồng Trà Kem Cheese',
      description: 'Hồng trà kết hợp lớp kem cheese béo mịn.',
      price: 45000,
      imageUrl: '',
      categoryId: 'Trà',
      isAvailable: true,
    ),
  ];

  @override
  Future<List<ProductModel>> getProducts() async => _products;

  @override
  Future<List<String>> getCategories() async => const [
    'Trà',
    'Trà sữa',
    'Trà trái cây',
  ];

  @override
  Future<List<Map<String, dynamic>>> getCampaigns() async => const [
    {
      'code': 'MAXKO20',
      'title': 'Giảm 20%',
      'description': 'Áp dụng cho đơn từ 80.000đ',
    },
    {
      'code': 'FREESHIP',
      'title': 'Miễn phí giao hàng',
      'description': 'Áp dụng cho đơn giao hàng',
    },
  ];
}
