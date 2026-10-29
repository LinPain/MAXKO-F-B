import 'package:flutter_test/flutter_test.dart';
import 'package:maxko_fb/data/models/product_model.dart';
import 'package:maxko_fb/data/models/product_option_model.dart';
import 'package:maxko_fb/modules/menu/controllers/product_detail_controller.dart';

void main() {
  group('ProductDetailController', () {
    test('uses backend product options directly without mock fallbacks', () {
      const product = ProductModel(
        id: 'p-1',
        name: 'Hồng Trà Sữa',
        description: 'Thơm béo',
        price: 35000,
        imageUrl: '',
        categoryId: 'cat-1',
        isAvailable: true,
        sizes: [
          ProductOptionModel(id: 's-m', name: 'M', extraPrice: 0, isAvailable: true),
          ProductOptionModel(id: 's-l', name: 'L', extraPrice: 5000, isAvailable: true),
        ],
        sugarLevels: [
          ProductOptionModel(id: 's-50', name: '50%', extraPrice: 0, isAvailable: true),
        ],
      );

      final controller = ProductDetailController(product: product);
      controller.onInit();

      expect(controller.sizes.length, equals(2));
      expect(controller.sugarLevels.length, equals(1));
      expect(controller.iceLevels, isEmpty);
      expect(controller.toppings, isEmpty);
      expect(controller.isValid, isTrue);
      expect(controller.selectedSize.value?.name, equals('M'));
      expect(controller.selectedSugar.value?.name, equals('50%'));
    });
  });
}
