import 'package:equatable/equatable.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final int discountAmount; // Nominal Rupiah diskon

  const CartState({
    this.items = const [],
    this.discountAmount = 0,
  });

  /// Subtotal seluruh item di keranjang
  int get subtotal => items.fold<int>(0, (sum, item) => sum + item.subtotal);

  /// Total akhir setelah dikurangi diskon (tidak boleh kurang dari 0)
  int get totalAmount {
    final total = subtotal - discountAmount;
    return total < 0 ? 0 : total;
  }

  /// Total kuantitas seluruh item
  int get totalItemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    int? discountAmount,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  @override
  List<Object?> get props => [items, discountAmount];
}
