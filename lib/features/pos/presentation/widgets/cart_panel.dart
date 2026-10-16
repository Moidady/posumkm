import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_state.dart';

class CartPanel extends StatelessWidget {
  final VoidCallback onCheckoutPressed;

  const CartPanel({
    super.key,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            children: [
              // Header Keranjang
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Pesanan (${state.totalItemCount})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (state.items.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          context.read<CartBloc>().add(const ClearCartEvent());
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                  ],
                ),
              ),

              // Daftar Item Keranjang
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted.withAlpha(120)),
                            const SizedBox(height: 12),
                            const Text(
                              'Keranjang Masih Kosong',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pilih menu di samping untuk menambahkan',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.items.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kuantitas & Tombol Ubah
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        context.read<CartBloc>().add(
                                              UpdateCartItemQuantityEvent(
                                                cartItemId: item.id,
                                                newQuantity: item.quantity - 1,
                                              ),
                                            );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        context.read<CartBloc>().add(
                                              UpdateCartItemQuantityEvent(
                                                cartItemId: item.id,
                                                newQuantity: item.quantity + 1,
                                              ),
                                            );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.add, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Produk & Modifier
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (item.selectedModifiers.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          item.selectedModifiers.map((m) => m.name).join(', '),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    if (item.notes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Catatan: ${item.notes}',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.warning),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Subtotal Item
                              Text(
                                CurrencyFormatter.format(item.subtotal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Rangkuman Harga & Tombol Bayar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: AppColors.cardBorder)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(
                          CurrencyFormatter.format(state.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    if (state.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon', style: TextStyle(color: AppColors.error, fontSize: 13)),
                          Text(
                            '-${CurrencyFormatter.format(state.discountAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Akhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          CurrencyFormatter.format(state.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tombol Bayar Kasir
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.items.isEmpty ? null : onCheckoutPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.cardBorder,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bayar (${CurrencyFormatter.format(state.totalAmount)})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
