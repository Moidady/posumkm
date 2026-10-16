import 'package:flutter/material.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';
import 'package:pos_umkm/features/pos/presentation/widgets/modifier_selection_modal.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(Product product, List<ProductModifier> modifiers, String notes)
      onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  void _handleTap(BuildContext context) {
    if (product.modifiers.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ModifierSelectionModal(
          product: product,
          onConfirm: (modifiers, notes) =>
              onAddToCart(product, modifiers, notes),
        ),
      );
    } else {
      onAddToCart(product, const [], '');
    }
  }

  Color _getAccentColor() {
    switch (product.categoryId) {
      case 'cat-lumpia':
        return const Color(0xFF7B1FA2); // Ungu Ubi
      case 'cat-potato':
        return const Color(0xFFE65100); // Keju Panggang
      case 'cat-boba':
        return const Color(0xFF5D4037); // Brown Sugar Boba
      case 'cat-matcha':
        return const Color(0xFF2E7D32); // Pure Matcha Green
      case 'cat-mojito':
        return const Color(0xFF0277BD); // Fresh Mojito Blue/Lime
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon() {
    switch (product.categoryId) {
      case 'cat-lumpia':
        return Icons.fastfood;
      case 'cat-potato':
        return Icons.bakery_dining;
      case 'cat-boba':
        return Icons.bubble_chart;
      case 'cat-matcha':
        return Icons.emoji_food_beverage;
      case 'cat-mojito':
        return Icons.local_bar;
      default:
        return Icons.restaurant_menu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final hasAssetImage = product.imageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bagian Atas: Foto Menu Asli + Badge Varian
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasAssetImage)
                    Image.asset(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallbackVisual(accentColor),
                    )
                  else
                    _buildFallbackVisual(accentColor),

                  // Gradien tipis di bawah gambar agar kontras
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(110),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badge Pilihan Ubi / Varian di Pojok Kanan Atas
                  if (product.modifiers.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(165),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.categoryId == 'cat-lumpia' ||
                                  product.categoryId == 'cat-potato'
                              ? 'Pilih Isian'
                              : '${product.modifiers.length} Opsi',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Badge Harga di Pojok Kiri Bawah Gambar
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        CurrencyFormatter.format(product.basePrice),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bagian Bawah: Nama Produk & Tombol Tambah
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.categoryId == 'cat-lumpia' ||
                                    product.categoryId == 'cat-potato'
                                ? 'Ubi Ungu / Cilembu'
                                : product.sku,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackVisual(Color accentColor) {
    return Container(
      color: accentColor.withAlpha(25),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 44,
          color: accentColor,
        ),
      ),
    );
  }
}
