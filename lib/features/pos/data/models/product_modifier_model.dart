import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';

class ProductModifierModel extends ProductModifier {
  const ProductModifierModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.extraPrice,
    required super.groupName,
  });

  factory ProductModifierModel.fromMap(Map<String, dynamic> map) {
    return ProductModifierModel(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      name: map['name'] as String,
      extraPrice: map['extra_price'] as int? ?? 0,
      groupName: map['group_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'extra_price': extraPrice,
      'group_name': groupName,
    };
  }
}
