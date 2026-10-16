import 'package:flutter_test/flutter_test.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/usecases/verify_qris_proof_usecase.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';
import 'package:pos_umkm/features/settings/domain/entities/store_settings.dart';

void main() {
  group('PosUmkm Unit Tests', () {
    test('CurrencyFormatter memformat angka integer ke format Rupiah standar', () {
      expect(CurrencyFormatter.format(15000), 'Rp 15.000');
      expect(CurrencyFormatter.format(1450000), 'Rp 1.450.000');
      expect(CurrencyFormatter.parse('Rp 38.500'), 38500);
    });

    test('CartItem menghitung unitPrice dan subtotal dengan modifiers dengan benar', () {
      const product = Product(
        id: 'prod-1',
        categoryId: 'cat-1',
        name: 'Mojito Series',
        basePrice: 18000,
        sku: 'MJT-01',
      );

      const modifier = ProductModifier(
        id: 'mod-1',
        productId: 'prod-1',
        name: 'Extra Boba',
        extraPrice: 3000,
        groupName: 'Topping',
      );

      const cartItem = CartItem(
        id: 'item-1',
        product: product,
        quantity: 2,
        selectedModifiers: [modifier],
      );

      expect(cartItem.unitPrice, 21000); // 18000 + 3000
      expect(cartItem.subtotal, 42000); // 21000 * 2
    });

    test('VerifyQrisProofUseCase memvalidasi syarat anti-fraud QRIS (Aturan #7 AGENT.md)', () {
      final useCase = VerifyQrisProofUseCase();
      final now = DateTime(2026, 10, 16, 17, 30);

      // 1. Bukti Valid
      final validRes = useCase.validateProof(
        expectedAmount: 38500,
        detectedAmount: 38500,
        transactionTime: now.subtract(const Duration(minutes: 3)),
        statusText: 'Transaksi Berhasil',
        referenceNumber: 'RRN-9988',
        currentTime: now,
      );
      expect(validRes.isValid, true);
      expect(validRes.referenceNumber, 'RRN-9988');

      // 2. Bukti Kedaluwarsa (> 10 menit)
      final expiredRes = useCase.validateProof(
        expectedAmount: 38500,
        detectedAmount: 38500,
        transactionTime: now.subtract(const Duration(minutes: 15)),
        statusText: 'Transaksi Berhasil',
        referenceNumber: 'RRN-9988',
        currentTime: now,
      );
      expect(expiredRes.isValid, false);
      expect(
        expiredRes.errorMessage,
        'Bukti transfer kedaluwarsa atau jam transaksi melebihi batas 10 menit. Pastikan pembeli menunjukkan bukti transaksi baru.',
      );

      // 3. Nominal Tidak Cocok
      final wrongAmountRes = useCase.validateProof(
        expectedAmount: 38500,
        detectedAmount: 30000,
        transactionTime: now,
        statusText: 'Transaksi Berhasil',
        referenceNumber: 'RRN-9988',
        currentTime: now,
      );
      expect(wrongAmountRes.isValid, false);
      expect(
        wrongAmountRes.errorMessage,
        'Nominal bukti bayar (Rp 30.000) tidak sesuai dengan total tagihan (Rp 38.500).',
      );
    });

    test('StoreSettings copyWith memperbarui nama toko dan nomor WA Owner dengan benar', () {
      const settings = StoreSettings(
        id: 'default-store',
        storeName: 'Kedai Pos UMKM',
        address: 'Jl. Kuliner',
        phoneNumber: '0812',
        ownerWhatsappNumber: '081234567890',
        ownerPinHash: '123456',
      );

      final updated = settings.copyWith(
        storeName: 'Lumpia & Boba Juara',
        ownerWhatsappNumber: '089988776655',
      );

      expect(updated.storeName, 'Lumpia & Boba Juara');
      expect(updated.ownerWhatsappNumber, '089988776655');
      expect(updated.ownerPinHash, '123456');
    });
  });
}
