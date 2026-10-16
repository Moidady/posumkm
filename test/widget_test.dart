import 'package:flutter_test/flutter_test.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';

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
  });
}
