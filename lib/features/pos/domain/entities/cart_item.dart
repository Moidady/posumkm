import 'package:equatable/equatable.dart';
import 'product.dart';
import 'product_modifier.dart';

/// Item pesanan di dalam keranjang belanja kasir.
class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final List<ProductModifier> selectedModifiers;
  final String notes;

  const CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.notes = '',
  });

  /// Harga satuan termasuk seluruh ekstra harga dari modifier yang dipilih
  int get unitPrice {
    final modifiersTotal = selectedModifiers.fold<int>(
      0,
      (sum, mod) => sum + mod.extraPrice,
    );
    return product.basePrice + modifiersTotal;
  }

  /// Total harga untuk item ini (unitPrice * quantity)
  int get subtotal => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    List<ProductModifier>? selectedModifiers,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, selectedModifiers, notes];
}
