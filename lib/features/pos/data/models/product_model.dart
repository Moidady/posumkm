import 'package:pos_umkm/features/pos/data/models/product_modifier_model.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.basePrice,
    required super.sku,
    super.imageUrl,
    super.isAvailable,
    super.modifiers,
  });

  factory ProductModel.fromMap(
    Map<String, dynamic> map, {
    List<ProductModifierModel> modifiers = const [],
  }) {
    return ProductModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      basePrice: map['base_price'] as int? ?? 0,
      sku: map['sku'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      isAvailable: (map['is_available'] as int? ?? 1) == 1,
      modifiers: modifiers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'base_price': basePrice,
      'sku': sku,
      'image_url': imageUrl,
      'is_available': isAvailable ? 1 : 0,
    };
  }
}
