class ProductOptionModel {
  final String id;
  final String name;
  final double extraPrice;
  final bool isAvailable;
  final String groupId;
  final String groupName;

  const ProductOptionModel({
    required this.id,
    required this.name,
    required this.extraPrice,
    required this.isAvailable,
    this.groupId = '',
    this.groupName = '',
  });

  factory ProductOptionModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ProductOptionModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['name']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ??
          (json['priceAdjustment'] as num?)?.toDouble() ??
          0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      groupId: json['groupId']?.toString() ?? '',
      groupName: json['groupName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraPrice': extraPrice,
      'isAvailable': isAvailable,
      'groupId': groupId,
      'groupName': groupName,
    };
  }
}
