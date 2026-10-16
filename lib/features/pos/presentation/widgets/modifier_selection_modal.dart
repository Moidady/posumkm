import 'package:flutter/material.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';

class ModifierSelectionModal extends StatefulWidget {
  final Product product;
  final Function(List<ProductModifier> selectedModifiers, String notes) onConfirm;

  const ModifierSelectionModal({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  @override
  State<ModifierSelectionModal> createState() => _ModifierSelectionModalState();
}

class _ModifierSelectionModalState extends State<ModifierSelectionModal> {
  final Set<ProductModifier> _selectedModifiers = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _calculatedUnitPrice {
    final modTotal = _selectedModifiers.fold<int>(0, (sum, m) => sum + m.extraPrice);
    return widget.product.basePrice + modTotal;
  }

  @override
  Widget build(BuildContext context) {
    // Kelompokkan modifier berdasarkan groupName (contoh: Level Gula, Level Es, Topping Ekstra)
    final Map<String, List<ProductModifier>> grouped = {};
    for (final mod in widget.product.modifiers) {
      grouped.putIfAbsent(mod.groupName, () => []).add(mod);
    }

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(widget.product.basePrice),
                        style: const TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Tampilkan kelompok modifier
            ...grouped.entries.map((entry) {
              final groupName = entry.key;
              final modifiers = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: modifiers.map((mod) {
                        final isSelected = _selectedModifiers.contains(mod);
                        return FilterChip(
                          label: Text(
                            mod.extraPrice > 0
                                ? '${mod.name} (+${CurrencyFormatter.format(mod.extraPrice)})'
                                : mod.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: AppColors.background,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                // Jika kategori level gula/es, biasanya pilih salah satu (radio style)
                                if (groupName.toLowerCase().contains('level')) {
                                  _selectedModifiers.removeWhere((m) => m.groupName == groupName);
                                }
                                _selectedModifiers.add(mod);
                              } else {
                                _selectedModifiers.remove(mod);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),

            // Input Catatan Khusus
            const Text(
              'Catatan Khusus (Opsional):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Pisahkan sambal, es sedikit...',
                hintStyle: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Konfirmasi Tambah ke Keranjang
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(
                    _selectedModifiers.toList(),
                    _notesController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tambah ke Pesanan'),
                    Text(
                      CurrencyFormatter.format(_calculatedUnitPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
