import 'package:get/get.dart';

import '../../../data/models/cart_item_model.dart';

class CartController extends GetxController {
  final cartItems = <CartItemModel>[].obs;

  double get subtotal {
    return cartItems.fold(
      0,
          (sum, item) => sum + item.totalPrice,
    );
  }

  double get total {
    return subtotal;
  }

  int get totalItems {
    return cartItems.fold(
      0,
          (sum, item) => sum + item.quantity,
    );
  }

  void addItem(CartItemModel item) {
    cartItems.add(item);
  }

  void removeItem(int index) {
    if (index < 0 || index >= cartItems.length) {
      return;
    }

    cartItems.removeAt(index);
  }

  void updateQuantity(
      int index,
      int quantity,
      ) {
    if (index < 0 || index >= cartItems.length) {
      return;
    }

    if (quantity <= 0) {
      removeItem(index);
      return;
    }

    final currentItem = cartItems[index];

    cartItems[index] = CartItemModel(
      productId: currentItem.productId,
      productName: currentItem.productName,
      unitPrice: currentItem.unitPrice,
      imageUrl: currentItem.imageUrl,
      brandId: currentItem.brandId,
      branchId: currentItem.branchId,
      quantity: quantity,
      customization: currentItem.customization,
    );
  }

  void clearCart() {
    cartItems.clear();
  }
}
