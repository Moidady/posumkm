import 'package:equatable/equatable.dart';

/// Entitas modifier/varian produk (contoh: Boba, Less Sugar, Extra Cheese).
class ProductModifier extends Equatable {
  final String id;
  final String productId;
  final String name;
  final int extraPrice; // Dalam Rupiah integer (misal: 3000 untuk +Rp 3.000)
  final String groupName; // contoh: "Level Gula", "Level Es", "Topping Ekstra"

  const ProductModifier({
    required this.id,
    required this.productId,
    required this.name,
    required this.extraPrice,
    required this.groupName,
  });

  @override
  List<Object?> get props => [id, productId, name, extraPrice, groupName];
}
