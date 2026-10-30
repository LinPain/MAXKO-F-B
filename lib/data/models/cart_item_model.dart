import 'product_customization_model.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final String imageUrl;
  final String brandId;
  final String branchId;

  final int quantity;

  final ProductCustomizationModel customization;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.imageUrl,
    this.brandId = 'brand-legia',
    this.branchId = '',
    required this.quantity,
    required this.customization,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'imageUrl': imageUrl,
      'brandId': brandId,
      'branchId': branchId,
      'quantity': quantity,
      'customization': customization.toJson(),
    };
  }
  factory CartItemModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CartItemModel(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] ?? '',
      unitPrice:
      (json['unitPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      brandId: json['brandId']?.toString() ?? 'brand-legia',
      branchId: json['branchId']?.toString() ?? '',
      quantity:
      (json['quantity'] as num?)?.toInt() ?? 0,
      customization: ProductCustomizationModel.fromJson(
        json['customization']
        as Map<String, dynamic>? ??
            {},
      ),
    );
  }
}
