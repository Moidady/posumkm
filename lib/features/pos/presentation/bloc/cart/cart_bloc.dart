import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:uuid/uuid.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  static const _uuid = Uuid();

  CartBloc() : super(const CartState()) {
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateQuantity);
    on<RemoveCartItemEvent>(_onRemoveItem);
    on<ApplyDiscountEvent>(_onApplyDiscount);
    on<ClearCartEvent>(_onClearCart);
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final currentItems = List<CartItem>.from(state.items);

    // Cek apakah item yang sama persis (produk sama, modifiers sama, catatan sama) sudah ada
    final existingIndex = currentItems.indexWhere((item) {
      if (item.product.id != event.product.id) return false;
      if (item.notes.trim() != event.notes.trim()) return false;
      if (item.selectedModifiers.length != event.selectedModifiers.length) return false;

      final currentModIds = item.selectedModifiers.map((m) => m.id).toSet();
      final newModIds = event.selectedModifiers.map((m) => m.id).toSet();
      return currentModIds.containsAll(newModIds);
    });

    if (existingIndex != -1) {
      final existing = currentItems[existingIndex];
      currentItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
    } else {
      currentItems.add(CartItem(
        id: _uuid.v4(),
        product: event.product,
        quantity: event.quantity,
        selectedModifiers: event.selectedModifiers,
        notes: event.notes,
      ));
    }

    emit(state.copyWith(items: currentItems));
  }

  void _onUpdateQuantity(UpdateCartItemQuantityEvent event, Emitter<CartState> emit) {
    final currentItems = List<CartItem>.from(state.items);
    final index = currentItems.indexWhere((item) => item.id == event.cartItemId);

    if (index != -1) {
      if (event.newQuantity <= 0) {
        currentItems.removeAt(index);
      } else {
        currentItems[index] = currentItems[index].copyWith(quantity: event.newQuantity);
      }
      emit(state.copyWith(items: currentItems));
    }
  }

  void _onRemoveItem(RemoveCartItemEvent event, Emitter<CartState> emit) {
    final currentItems = state.items.where((item) => item.id != event.cartItemId).toList();
    emit(state.copyWith(items: currentItems));
  }

  void _onApplyDiscount(ApplyDiscountEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(discountAmount: event.discountAmount));
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(const CartState());
  }
}
