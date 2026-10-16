import 'package:equatable/equatable.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCartEvent extends CartEvent {
  final Product product;
  final List<ProductModifier> selectedModifiers;
  final String notes;
  final int quantity;

  const AddToCartEvent({
    required this.product,
    this.selectedModifiers = const [],
    this.notes = '',
    this.quantity = 1,
  });

  @override
  List<Object?> get props => [product, selectedModifiers, notes, quantity];
}

class UpdateCartItemQuantityEvent extends CartEvent {
  final String cartItemId;
  final int newQuantity;

  const UpdateCartItemQuantityEvent({
    required this.cartItemId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [cartItemId, newQuantity];
}

class RemoveCartItemEvent extends CartEvent {
  final String cartItemId;
  const RemoveCartItemEvent(this.cartItemId);

  @override
  List<Object?> get props => [cartItemId];
}

class ApplyDiscountEvent extends CartEvent {
  final int discountAmount; // Nominal Rupiah integer
  const ApplyDiscountEvent(this.discountAmount);

  @override
  List<Object?> get props => [discountAmount];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}
