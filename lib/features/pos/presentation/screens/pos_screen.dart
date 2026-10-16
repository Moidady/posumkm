import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pos_umkm/features/auth/presentation/widgets/multi_device_sync_dialog.dart';
import 'package:pos_umkm/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:pos_umkm/features/checkout/presentation/widgets/checkout_dialog.dart';
import 'package:pos_umkm/features/checkout/presentation/widgets/digital_receipt_dialog.dart';
import 'package:pos_umkm/features/history_and_reports/data/services/excel_export_service.dart';
import 'package:pos_umkm/features/history_and_reports/presentation/screens/analytics_dashboard_screen.dart';
import 'package:pos_umkm/features/history_and_reports/presentation/widgets/order_history_dialog.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_state.dart';
import 'package:pos_umkm/features/pos/presentation/widgets/cart_panel.dart';
import 'package:pos_umkm/features/pos/presentation/widgets/product_card.dart';
import 'package:pos_umkm/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:pos_umkm/features/settings/presentation/screens/store_and_menu_settings_screen.dart';
import 'package:pos_umkm/features/settings/presentation/widgets/owner_pin_dialog.dart';
import 'package:pos_umkm/features/shift/presentation/widgets/close_shift_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Muat katalog produk saat pertama kali layar dibuka
    context.read<CatalogBloc>().add(const LoadCatalogEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCheckoutModal(BuildContext context, CartState cartState) {
    if (cartState.items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CheckoutDialog(
        cartItems: cartState.items,
        subtotal: cartState.subtotal,
        discountAmount: cartState.discountAmount,
        totalAmount: cartState.totalAmount,
      ),
    );
  }

  void _openCloseShiftModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CloseShiftDialog(),
    );
  }

  void _openHistoryModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const OrderHistoryDialog(),
    );
  }

  void _openMultiDeviceModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const MultiDeviceSyncDialog(),
    );
  }

  void _openAnalyticsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsDashboardScreen(),
      ),
    );
  }

  Future<void> _openOwnerSettings(BuildContext context) async {
    final currentUser = context.read<AuthCubit>().state.currentUser;
    if (currentUser == null || !currentUser.isOwner) {
      final authorized = await OwnerPinDialog.verify(
        context,
        title: 'Akses Owner: Kelola Menu & Toko',
        subtitle:
            'Masukkan PIN Owner untuk mengubah harga menu atau pengaturan toko (Default: 123456).',
      );
      if (!authorized || !context.mounted) return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoreAndMenuSettingsScreen(),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyiapkan file Excel 3-Sheet...'),
          duration: Duration(seconds: 1),
        ),
      );
      final savedFile = await ExcelExportService().exportMonthlyReport();
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ File Excel berhasil diunduh: $savedFile'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor Excel: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutSuccess) {
          // Kosongkan keranjang belanja setelah lunas
          context.read<CartBloc>().add(const ClearCartEvent());
          // Tampilkan modal struk digital begitu transaksi berhasil
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => DigitalReceiptDialog(receipt: state.receipt),
          );
        } else if (state is CheckoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settingsState.settings.storeName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          settingsState.settings.address,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            // Badge Kasir Aktif & Perangkat HP (Klik untuk Multi-HP Sync / Ganti Kasir)
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final userLabel =
                    authState.currentUser?.username.toUpperCase() ?? 'KASIR';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => _openMultiDeviceModal(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.info.withAlpha(90)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.devices_rounded,
                            size: 15,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$userLabel • ${authState.activeDeviceName}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Tombol Dashboard Analitik & Grafik Penjualan
            IconButton(
              tooltip: 'Dashboard Analitik & Grafik Penjualan',
              icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              onPressed: () => _openAnalyticsScreen(context),
            ),
            // Tombol Riwayat Transaksi, Void, & Kas Kecil
            IconButton(
              tooltip: 'Riwayat Transaksi, Void, & Kas Laci',
              icon: const Icon(Icons.history, color: AppColors.primary),
              onPressed: () => _openHistoryModal(context),
            ),
            // Tombol Kelola Menu & Pengaturan Toko (PIN Owner)
            IconButton(
              tooltip: 'Kelola Menu, Harga, & Pengaturan Toko (Owner)',
              icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
              onPressed: () => _openOwnerSettings(context),
            ),
            // Tombol Ekspor Excel
            IconButton(
              tooltip: 'Ekspor Excel Bulanan (.xlsx)',
              icon: const Icon(Icons.table_view_outlined, color: AppColors.primary),
              onPressed: () => _exportExcel(context),
            ),
            // Tombol Tutup Toko / Rekap Shift
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _openCloseShiftModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight.withAlpha(40),
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.storefront, size: 18),
                label: const Text('Tutup Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTabletLandscape = constraints.maxWidth >= 750;

            if (isTabletLandscape) {
              // ==========================================
              // LAYOUT TABLET / DESKTOP (MASTER-DETAIL SPLIT)
              // ==========================================
              return Row(
                children: [
                  // Sisi Kiri: Katalog Produk (60%)
                  Expanded(
                    flex: 6,
                    child: _buildCatalogSection(context),
                  ),

                  // Sisi Kanan: Panel Keranjang Belanja Tetap (40%)
                  Expanded(
                    flex: 4,
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, cartState) {
                        return CartPanel(
                          onCheckoutPressed: () => _openCheckoutModal(context, cartState),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              // ==========================================
              // LAYOUT SMARTPHONE (PORTRAIT)
              // ==========================================
              return Column(
                children: [
                  Expanded(child: _buildCatalogSection(context)),

                  // Floating Bottom Cart Bar untuk Smartphone
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      if (cartState.items.isEmpty) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 8,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${cartState.totalItemCount} Menu Dipilih',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(cartState.totalAmount),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () => _openCheckoutModal(context, cartState),
                                icon: const Icon(Icons.payment, size: 18),
                                label: const Text('Bayar Sekarang'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCatalogSection(BuildContext context) {
    return Column(
      children: [
        // Search Bar & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: TextField(
            controller: _searchController,
            onChanged: (query) {
              context.read<CatalogBloc>().add(SearchProductEvent(query));
            },
            decoration: InputDecoration(
              hintText: 'Cari menu (Lumpia, Mojito, Boba, Matcha)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<CatalogBloc>().add(const SearchProductEvent(''));
                      },
                    )
                  : null,
            ),
          ),
        ),

        // Tab Kategori Horizontal
        BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            if (state is CatalogLoaded) {
              return SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryChip(
                      label: 'Semua Menu',
                      categoryId: 'all',
                      isSelected: state.selectedCategoryId == 'all',
                    ),
                    ...state.categories.map((cat) {
                      return _buildCategoryChip(
                        label: cat.name,
                        categoryId: cat.id,
                        isSelected: state.selectedCategoryId == cat.id,
                      );
                    }),
                  ],
                ),
              );
            }
            return const SizedBox(height: 42);
          },
        ),
        const SizedBox(height: 8),

        // Grid Menu Produk
        Expanded(
          child: BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state is CatalogLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CatalogError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(state.message, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<CatalogBloc>().add(const LoadCatalogEvent()),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (state is CatalogLoaded) {
                if (state.products.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada menu ditemukan.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 210,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onAddToCart: (prod, modifiers, notes) {
                        context.read<CartBloc>().add(
                              AddToCartEvent(
                                product: prod,
                                selectedModifiers: modifiers,
                                notes: notes,
                              ),
                            );
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${prod.name} ditambahkan'),
                            duration: const Duration(milliseconds: 900),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String categoryId,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) {
          context.read<CatalogBloc>().add(SelectCategoryEvent(categoryId));
        },
      ),
    );
  }
}
