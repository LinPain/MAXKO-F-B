import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_customization_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_option_model.dart';
import '../../cart/controllers/cart_controller.dart';

class ProductDetailController extends GetxController {
  final ProductModel product;

  ProductDetailController({required this.product});

  final selectedSize = Rxn<ProductOptionModel>();
  final selectedSugar = Rxn<ProductOptionModel>();
  final selectedIce = Rxn<ProductOptionModel>();

  final selectedToppings = <ProductOptionModel>[].obs;

  final quantity = 1.obs;

  final noteController = TextEditingController();

  List<ProductOptionModel> get sizes => product.sizes;
  List<ProductOptionModel> get sugarLevels => product.sugarLevels;
  List<ProductOptionModel> get iceLevels => product.iceLevels;
  List<ProductOptionModel> get toppings => product.toppings;

  @override
  void onInit() {
    super.onInit();
    if (sizes.isNotEmpty) selectedSize.value = sizes.first;
    if (sugarLevels.isNotEmpty) {
      selectedSugar.value = sugarLevels.firstWhere(
        (option) => option.name == '50%',
        orElse: () => sugarLevels.first,
      );
    }
    if (iceLevels.isNotEmpty) {
      selectedIce.value = iceLevels.firstWhere(
        (option) => option.name == 'Bình thường',
        orElse: () => iceLevels.first,
      );
    }
  }

  double get toppingTotal {
    return selectedToppings.fold(0, (sum, topping) => sum + topping.extraPrice);
  }

  double get sizeExtraPrice {
    return selectedSize.value?.extraPrice ?? 0;
  }

  double get unitPrice {
    return product.price +
        sizeExtraPrice +
        (selectedSugar.value?.extraPrice ?? 0) +
        (selectedIce.value?.extraPrice ?? 0) +
        toppingTotal;
  }

  double get totalPrice {
    return unitPrice * quantity.value;
  }

  bool get isValid {
    return sizes.isEmpty || selectedSize.value != null;
  }

  void selectSize(ProductOptionModel option) {
    selectedSize.value = option;
  }

  void selectSugar(ProductOptionModel option) {
    selectedSugar.value = option;
  }

  void selectIce(ProductOptionModel option) {
    selectedIce.value = option;
  }

  void toggleTopping(ProductOptionModel option) {
    if (selectedToppings.contains(option)) {
      selectedToppings.remove(option);
    } else {
      selectedToppings.add(option);
    }
  }

  void increaseQuantity() {
    quantity.value++;
  }

  void decreaseQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  ProductCustomizationModel get customization {
    return ProductCustomizationModel(
      sizeId: selectedSize.value?.id ?? '',
      sugarLevelId: selectedSugar.value?.id ?? '',
      iceLevelId: selectedIce.value?.id ?? '',
      toppingIds: selectedToppings.map((item) => item.id).toList(),
      note: noteController.text.trim(),
      selectedModifiers: [
        if (selectedSize.value != null)
          _toModifier(selectedSize.value!, 'mod-legia-size', 'Kích cỡ'),
        if (selectedSugar.value != null)
          _toModifier(selectedSugar.value!, 'mod-legia-sugar', 'Độ ngọt'),
        if (selectedIce.value != null)
          _toModifier(selectedIce.value!, 'mod-legia-ice', 'Lượng đá'),
        ...selectedToppings.map(
          (option) => _toModifier(option, 'mod-legia-toppings', 'Topping'),
        ),
      ],
    );
  }

  Map<String, dynamic> _toModifier(
    ProductOptionModel option,
    String fallbackGroupId,
    String fallbackGroupName,
  ) => {
    'groupId': option.groupId.isNotEmpty ? option.groupId : fallbackGroupId,
    'groupName': option.groupName.isNotEmpty
        ? option.groupName
        : fallbackGroupName,
    'optionId': option.id,
    'optionName': option.name,
    'priceAdjustment': option.extraPrice,
  };

  void addToCart() {
    if (!isValid) {
      Get.snackbar(
        'Chưa chọn size',
        'Vui lòng chọn kích thước ly.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final cartController = Get.find<CartController>();

    final cartItem = CartItemModel(
      productId: product.id,
      productName: product.name,
      unitPrice: unitPrice,
      imageUrl: product.imageUrl,
      brandId: product.brandId,
      branchId: product.branchId,
      quantity: quantity.value,
      customization: customization,
    );

    cartController.addItem(cartItem);

    Get.back();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
