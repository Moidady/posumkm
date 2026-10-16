import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/pos/domain/entities/category.dart';
import 'package:pos_umkm/features/pos/domain/entities/product.dart';
import 'package:pos_umkm/features/pos/domain/entities/product_modifier.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_event.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_state.dart';
import 'package:pos_umkm/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:uuid/uuid.dart';

class StoreAndMenuSettingsScreen extends StatefulWidget {
  const StoreAndMenuSettingsScreen({super.key});

  @override
  State<StoreAndMenuSettingsScreen> createState() =>
      _StoreAndMenuSettingsScreenState();
}

class _StoreAndMenuSettingsScreenState extends State<StoreAndMenuSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers Profil Toko
  late TextEditingController _storeNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _ownerWaCtrl;
  late TextEditingController _ownerPinCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final current = context.read<SettingsCubit>().state.settings;
    _storeNameCtrl = TextEditingController(text: current.storeName);
    _addressCtrl = TextEditingController(text: current.address);
    _phoneCtrl = TextEditingController(text: current.phoneNumber);
    _ownerWaCtrl = TextEditingController(text: current.ownerWhatsappNumber);
    _ownerPinCtrl = TextEditingController(text: current.ownerPinHash);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _ownerWaCtrl.dispose();
    _ownerPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStoreSettings() async {
    final current = context.read<SettingsCubit>().state.settings;
    final updated = current.copyWith(
      storeName: _storeNameCtrl.text,
      address: _addressCtrl.text,
      phoneNumber: _phoneCtrl.text,
      ownerWhatsappNumber: _ownerWaCtrl.text,
      ownerPinHash: _ownerPinCtrl.text,
    );

    final ok = await context.read<SettingsCubit>().saveSettings(updated);
    if (!mounted) return;

    final state = context.read<SettingsCubit>().state;
    if (state is SettingsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (state.successMessage ?? 'Pengaturan berhasil disimpan.')
                : (state.errorMessage ?? 'Gagal menyimpan pengaturan.'),
          ),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'Contoh: Paket Hemat / Snack Pedas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context
                    .read<CatalogBloc>()
                    .add(AddCategoryEvent(ctrl.text.trim()));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kategori "${ctrl.text.trim()}" ditambahkan!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showProductFormModal({
    Product? existingProduct,
    required List<Category> categories,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductFormDialog(
        existingProduct: existingProduct,
        categories: categories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Menu & Pengaturan Gerai (Owner)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.restaurant_menu),
              text: 'Kelola Menu & Harga',
            ),
            Tab(
              icon: Icon(Icons.store),
              text: 'Profil Toko & WA Owner',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==========================================
          // TAB 1: KELOLA MENU & HARGA
          // ==========================================
          BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state is CatalogLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CatalogLoaded) {
                final products = state.allProducts.isNotEmpty
                    ? state.allProducts
                    : state.products;
                final categories = state.categories;

                final categoryMap = {
                  for (final c in categories) c.id: c.name,
                };

                return Column(
                  children: [
                    // Action Bar Atas
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total Menu Terdaftar: ${products.length} Produk (${categories.length} Kategori)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _showAddCategoryDialog,
                            icon: const Icon(Icons.category_outlined, size: 18),
                            label: const Text('+ Kategori'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showProductFormModal(
                              categories: categories,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('+ Tambah Menu Baru'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Daftar Menu
                    Expanded(
                      child: products.isEmpty
                          ? const Center(
                              child: Text('Belum ada menu terdaftar.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: products.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final prod = products[idx];
                                final catName =
                                    categoryMap[prod.categoryId] ?? 'Lainnya';

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: prod.imageUrl.isNotEmpty
                                          ? Image.asset(
                                              prod.imageUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  CircleAvatar(
                                                backgroundColor: prod
                                                        .isAvailable
                                                    ? AppColors.primary
                                                        .withAlpha(25)
                                                    : Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.fastfood,
                                                  color: prod.isAvailable
                                                      ? AppColors.primary
                                                      : Colors.grey,
                                                ),
                                              ),
                                            )
                                          : CircleAvatar(
                                              backgroundColor: prod.isAvailable
                                                  ? AppColors.primary
                                                      .withAlpha(25)
                                                  : Colors.grey.shade200,
                                              child: Icon(
                                                Icons.fastfood,
                                                color: prod.isAvailable
                                                    ? AppColors.primary
                                                    : Colors.grey,
                                              ),
                                            ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            prod.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration: prod.isAvailable
                                                  ? null
                                                  : TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            catName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '${CurrencyFormatter.format(prod.basePrice)}  •  SKU: ${prod.sku}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (prod.modifiers.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Varian/Topping (${prod.modifiers.length}): ${prod.modifiers.map((m) => m.name).join(', ')}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Switch Stok Tersedia / Habis
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Switch(
                                              value: prod.isAvailable,
                                              activeThumbColor: AppColors.success,
                                              onChanged: (val) {
                                                context.read<CatalogBloc>().add(
                                                      ToggleProductAvailabilityEvent(
                                                        productId: prod.id,
                                                        isAvailable: val,
                                                      ),
                                                    );
                                              },
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          tooltip: 'Edit Menu & Harga',
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () =>
                                              _showProductFormModal(
                                            existingProduct: prod,
                                            categories: categories,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus Menu',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Hapus Menu?'),
                                                content: Text(
                                                  'Apakah Anda yakin ingin menghapus menu "${prod.name}" dari daftar katalog?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColors.error,
                                                    ),
                                                    onPressed: () {
                                                      context
                                                          .read<CatalogBloc>()
                                                          .add(
                                                            DeleteProductEvent(
                                                              prod.id,
                                                            ),
                                                          );
                                                      Navigator.pop(ctx);
                                                    },
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              }

              return const Center(child: Text('Gagal memuat daftar menu.'));
            },
          ),

          // ==========================================
          // TAB 2: PROFIL TOKO & WA OWNER
          // ==========================================
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Identitas Gerai & Tujuan Laporan Owner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Data ini digunakan pada Header Struk Digital serta tujuan pengiriman otomatis Laporan Tutup Toko ke WhatsApp Owner.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _storeNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Gerai / Toko UMKM',
                            prefixIcon: Icon(Icons.storefront),
                            hintText: 'Contoh: Kedai Lumpia & Boba Berkah',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Outlet',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            hintText: 'Contoh: Jl. Kuliner No. 12, Stand B-04',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon Gerai (Tampil di Struk)',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ownerWaCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText:
                                'Nomor WhatsApp Owner (Tujuan Rekap Tutup Toko)',
                            prefixIcon: Icon(
                              Icons.chat_outlined,
                              color: AppColors.success,
                            ),
                            helperText:
                                'Contoh: 081234567890 atau 6281234567890. Laporan harian otomatis dikirim ke nomor ini.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ownerPinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PIN Otorisasi Owner (Keamanan Harga & Void)',
                            prefixIcon: Icon(Icons.lock_outline),
                            helperText:
                                'Kasir membutuhkan PIN ini untuk membuka pengaturan harga atau membatalkan pesanan.',
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saveStoreSettings,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text(
                              'Simpan Pengaturan Gerai',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? existingProduct;
  final List<Category> categories;

  const _ProductFormDialog({
    this.existingProduct,
    required this.categories,
  });

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  static const _uuid = Uuid();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _skuCtrl;
  late String _selectedCategoryId;
  late bool _isAvailable;
  late List<ProductModifier> _modifiers;

  // Input untuk tambah modifier baru
  final TextEditingController _modNameCtrl = TextEditingController();
  final TextEditingController _modPriceCtrl = TextEditingController(text: '0');
  String _modGroup = 'Topping Ekstra';

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.basePrice.toString() : '',
    );
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _selectedCategoryId = p?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : 'cat-1');
    _isAvailable = p?.isAvailable ?? true;
    _modifiers = List<ProductModifier>.from(p?.modifiers ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _skuCtrl.dispose();
    _modNameCtrl.dispose();
    _modPriceCtrl.dispose();
    super.dispose();
  }

  void _addModifier() {
    final name = _modNameCtrl.text.trim();
    if (name.isEmpty) return;

    final extraPrice = CurrencyFormatter.parse(_modPriceCtrl.text);
    setState(() {
      _modifiers.add(
        ProductModifier(
          id: _uuid.v4(),
          productId: widget.existingProduct?.id ?? '',
          name: name,
          extraPrice: extraPrice,
          groupName: _modGroup,
        ),
      );
      _modNameCtrl.clear();
      _modPriceCtrl.text = '0';
    });
  }

  void _saveProduct() {
    final name = _nameCtrl.text.trim();
    final basePrice = CurrencyFormatter.parse(_priceCtrl.text);

    if (name.isEmpty || basePrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama menu dan harga dasar (Rp) wajib diisi dengan benar!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final productId = widget.existingProduct?.id ?? _uuid.v4();
    final product = Product(
      id: productId,
      categoryId: _selectedCategoryId,
      name: name,
      basePrice: basePrice,
      sku: _skuCtrl.text.trim(),
      imageUrl: widget.existingProduct?.imageUrl ?? '',
      isAvailable: _isAvailable,
      modifiers: _modifiers,
    );

    context.read<CatalogBloc>().add(SaveProductEvent(product));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menu "$name" berhasil disimpan!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProduct != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Menu & Harga' : 'Tambah Menu F&B Baru',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Menu Makanan / Minuman',
                          hintText: 'Contoh: Lumpia Beef Mozzarella',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: widget.categories
                                      .any((c) => c.id == _selectedCategoryId)
                                  ? _selectedCategoryId
                                  : (widget.categories.isNotEmpty
                                      ? widget.categories.first.id
                                      : null),
                              decoration: const InputDecoration(
                                labelText: 'Kategori Menu',
                              ),
                              items: widget.categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategoryId = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Dasar (Rupiah)',
                                hintText: 'Contoh: 18000',
                                prefixText: 'Rp ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Kode SKU (Opsional)',
                                hintText: 'Contoh: LMP-BEF',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Stok Tersedia',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: _isAvailable,
                              onChanged: (v) =>
                                  setState(() => _isAvailable = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Varian & Topping Tambahan (Modifiers)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _modGroup,
                                    decoration: const InputDecoration(
                                      labelText: 'Grup Varian',
                                      isDense: true,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Topping Ekstra',
                                        child: Text('Topping Ekstra'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Level Gula',
                                        child: Text('Level Gula'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Level Es',
                                        child: Text('Level Es'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Ukuran Cup',
                                        child: Text('Ukuran Cup'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => _modGroup = v);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _modNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama Pilihan',
                                      hintText: 'Keju / Less Sugar',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _modPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: '+Harga (Rp)',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tambah Varian',
                                  onPressed: _addModifier,
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (_modifiers.isNotEmpty) ...[
                              const Divider(height: 16),
                              ..._modifiers.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final mod = entry.value;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '[${mod.groupName}] ${mod.name}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        mod.extraPrice > 0
                                            ? '+${CurrencyFormatter.format(mod.extraPrice)}'
                                            : 'Gratis (Rp 0)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 18,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _modifiers.removeAt(idx);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveProduct,
                      icon: const Icon(Icons.check),
                      label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Menu'),
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
