import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/core/utils/date_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:share_plus/share_plus.dart';

class DigitalReceiptDialog extends StatelessWidget {
  final DigitalReceipt receipt;

  const DigitalReceiptDialog({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final order = receipt.order;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Sukses Badge
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 8),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                order.orderNumber,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Divider(height: 20),

              // Kartu Rincian Struk Digital
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(receipt.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(receipt.storeAddress, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('Waktu: ${DateFormatter.formatDateTime(order.createdAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Divider(height: 16),

                        // Daftar Item
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: const TextStyle(fontSize: 13)),
                                      if (item.notes.isNotEmpty)
                                        Text('Catatan: ${item.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text(CurrencyFormatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          );
                        }),

                        const Divider(height: 16),

                        // Subtotal & Diskon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(CurrencyFormatter.format(order.subtotal), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (order.discountAmount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon', style: TextStyle(fontSize: 12, color: AppColors.error)),
                              Text('-${CurrencyFormatter.format(order.discountAmount)}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Akhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(CurrencyFormatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          ],
                        ),
                        const Divider(height: 16),

                        // Metode Bayar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Metode Pembayaran', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        if (order.paymentMethod == 'CASH') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Uang Diterima', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(CurrencyFormatter.format(order.cashTendered), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Uang Kembalian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                              Text(CurrencyFormatter.format(order.changeDue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('No. Referensi (RRN)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text(order.qrisReferenceNo ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Bagikan WhatsApp & Transaksi Baru
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          receipt.toWhatsAppMessage(),
                          subject: 'Struk ${receipt.storeName} - ${order.orderNumber}',
                        );
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Kirim Struk WA'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<CartBloc>().add(const ClearCartEvent());
                        context.read<CheckoutBloc>().add(const ResetCheckoutEvent());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Pesanan Baru'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
