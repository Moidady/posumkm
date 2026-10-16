import 'package:equatable/equatable.dart';
import 'product_modifier.dart';

/// Entitas produk menu UMKM F&B.
class Product extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final int basePrice; // Nominal Rupiah integer murni (contoh: 18000 untuk Rp 18.000)
  final String sku;
  final String imageUrl;
  final bool isAvailable;
  final List<ProductModifier> modifiers;

  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    required this.sku,
    this.imageUrl = '',
    this.isAvailable = true,
    this.modifiers = const [],
  });

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        basePrice,
        sku,
        imageUrl,
        isAvailable,
        modifiers,
      ];
}
