import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/features/auth/data/services/multi_device_sync_service.dart';
import 'package:pos_umkm/features/auth/domain/entities/app_user.dart';
import 'package:pos_umkm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:pos_umkm/features/pos/presentation/bloc/catalog/catalog_event.dart';
import 'package:pos_umkm/features/settings/presentation/widgets/owner_pin_dialog.dart';

class MultiDeviceSyncDialog extends StatefulWidget {
  const MultiDeviceSyncDialog({super.key});

  @override
  State<MultiDeviceSyncDialog> createState() => _MultiDeviceSyncDialogState();
}

class _MultiDeviceSyncDialogState extends State<MultiDeviceSyncDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MultiDeviceSyncService _syncService = MultiDeviceSyncService();
  final TextEditingController _importJsonController = TextEditingController();

  bool _isSyncBusy = false;
  String? _syncStatusMessage;
  bool _isSyncSuccess = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AuthCubit>().loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importJsonController.dispose();
    super.dispose();
  }

  Future<void> _exportAndCopySyncData(AuthState authState) async {
    setState(() {
      _isSyncBusy = true;
      _syncStatusMessage = null;
    });

    try {
      final jsonStr = await _syncService.exportSyncJson(
        deviceName: authState.activeDeviceName,
        cashierName: authState.currentUser?.fullName ?? 'Kasir',
      );
      await Clipboard.setData(ClipboardData(text: jsonStr));
      setState(() {
        _isSyncBusy = false;
        _isSyncSuccess = true;
        _syncStatusMessage =
            '✅ Paket data dari ${authState.activeDeviceName} berhasil disalin ke Clipboard! '
            'Kirimkan via WhatsApp ke HP Owner/Utama lalu tempel di kolom "Gabungkan Data" di bawah.';
      });
    } catch (e) {
      setState(() {
        _isSyncBusy = false;
        _isSyncSuccess = false;
        _syncStatusMessage = 'Gagal mengekspor data: $e';
      });
    }
  }

  Future<void> _importAndMergeSyncData() async {
    final raw = _importJsonController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _isSyncSuccess = false;
        _syncStatusMessage =
            'Tempelkan kode JSON sinkronisasi dari HP Kasir lain terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSyncBusy = true;
      _syncStatusMessage = null;
    });

    try {
      final result = await _syncService.importSyncJson(raw);
      if (!mounted) return;
      context.read<CatalogBloc>().add(const LoadCatalogEvent());
      context.read<AuthCubit>().loadUsers();
      _importJsonController.clear();
      setState(() {
        _isSyncBusy = false;
        _isSyncSuccess = true;
        _syncStatusMessage =
            '✅ Sinkronisasi Berhasil dari ${result.sourceDevice} (${result.exportedBy})!\n'
            '• ${result.ordersMerged} Transaksi & ${result.itemsMerged} Item Pesanan digabungkan\n'
            '• ${result.productsMerged} Menu & ${result.usersMerged} Akun Kasir diperbarui.';
      });
    } catch (e) {
      setState(() {
        _isSyncBusy = false;
        _isSyncSuccess = false;
        _syncStatusMessage = 'Gagal menggabungkan data: $e';
      });
    }
  }

  Future<void> _showAddOrEditCashierModal(
    BuildContext context, {
    AppUser? existingUser,
  }) async {
    final currentUser = context.read<AuthCubit>().state.currentUser;
    if (currentUser == null || !currentUser.isOwner) {
      final authorized = await OwnerPinDialog.verify(
        context,
        title: 'Otorisasi Owner Diperlukan',
        subtitle:
            'Masukkan PIN Owner untuk menambah atau mengubah akun login HP Kasir.',
      );
      if (!authorized || !context.mounted) return;
    }

    final usernameCtrl =
        TextEditingController(text: existingUser?.username ?? '');
    final fullNameCtrl =
        TextEditingController(text: existingUser?.fullName ?? '');
    final pinCtrl = TextEditingController(text: existingUser?.pinCode ?? '');
    final deviceCtrl = TextEditingController(
      text: existingUser?.assignedDevice ?? 'HP-KASIR-3',
    );
    String selectedRole = existingUser?.role ?? 'CASHIER';
    bool isActive = existingUser?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(
                existingUser == null
                    ? 'Tambah Akun HP Kasir Baru'
                    : 'Edit Akun ${existingUser.fullName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kasir / Label HP',
                        hintText: 'Contoh: Kasir 3 (HP Depan)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username Login',
                        hintText: 'Contoh: kasir3 (tanpa spasi)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN / Password Login',
                        hintText: 'Contoh: 333333',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: deviceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kode Perangkat / HP Kasir',
                        hintText: 'Contoh: HP-KASIR-3 atau TABLET-2',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Peran Akses'),
                      items: const [
                        DropdownMenuItem(
                          value: 'CASHIER',
                          child: Text('CASHIER (Kasir HP / Tablet)'),
                        ),
                        DropdownMenuItem(
                          value: 'OWNER',
                          child: Text('OWNER (Pemilik / Admin Penuh)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Status Akun Aktif',
                          style: TextStyle(fontSize: 13)),
                      value: isActive,
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (usernameCtrl.text.trim().isEmpty ||
                        fullNameCtrl.text.trim().isEmpty ||
                        pinCtrl.text.trim().isEmpty) {
                      return;
                    }
                    await context.read<AuthCubit>().saveCashierAccount(
                          id: existingUser?.id,
                          username: usernameCtrl.text,
                          fullName: fullNameCtrl.text,
                          pinCode: pinCtrl.text,
                          role: selectedRole,
                          assignedDevice: deviceCtrl.text.trim().isEmpty
                              ? 'HP-KASIR'
                              : deviceCtrl.text,
                          isActive: isActive,
                        );
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Text('Simpan Akun'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.devices_rounded, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Multi-HP Kasir, Login, & Sinkronisasi',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  // Bar Info Sesi Aktif
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Login Aktif: ${authState.currentUser?.fullName ?? "-"} '
                            '(@${authState.currentUser?.username ?? "-"}) • '
                            'Perangkat: ${authState.activeDeviceName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AuthCubit>().logout();
                          },
                          icon: const Icon(Icons.logout,
                              size: 16, color: AppColors.error),
                          label: const Text(
                            'Ganti Kasir / Logout',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.manage_accounts_outlined, size: 18),
                        text: 'Akun Login Tiap HP Kasir',
                      ),
                      Tab(
                        icon: Icon(Icons.sync_alt_rounded, size: 18),
                        text: 'Gabung Data 2+ HP / Tablet',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ==========================================
                        // TAB 1: DAFTAR AKUN LOGIN PER HP KASIR
                        // ==========================================
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Setiap HP/Tablet kasir memiliki akun login & kode perangkat sendiri agar transaksi tidak bentrok:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showAddOrEditCashierModal(context),
                                  icon: const Icon(Icons.person_add_alt_1,
                                      size: 16),
                                  label: const Text(
                                    'Tambah HP Kasir',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.separated(
                                itemCount: authState.availableUsers.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final u = authState.availableUsers[index];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: u.isOwner
                                              ? AppColors.warning.withAlpha(35)
                                              : AppColors.primary.withAlpha(25),
                                          child: Icon(
                                            u.isOwner
                                                ? Icons.admin_panel_settings
                                                : Icons.phone_android_rounded,
                                            color: u.isOwner
                                                ? AppColors.warning
                                                : AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    u.fullName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.info
                                                          .withAlpha(25),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      u.assignedDevice,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.info,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Username: ${u.username}  •  PIN: ${u.pinCode}  •  Peran: ${u.role}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Edit Akun / PIN Kasir',
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18,
                                              color: AppColors.primary),
                                          onPressed: () =>
                                              _showAddOrEditCashierModal(
                                            context,
                                            existingUser: u,
                                          ),
                                        ),
                                        if (!u.isOwner)
                                          IconButton(
                                            tooltip: 'Hapus Akun Kasir',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: AppColors.error),
                                            onPressed: () async {
                                              await context
                                                  .read<AuthCubit>()
                                                  .deleteCashierAccount(u.id);
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // ==========================================
                        // TAB 2: SINKRONISASI & GABUNG DATA 2+ HP
                        // ==========================================
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cara 1: Sinkronisasi Antar HP Offline/WhatsApp
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Langkah 1: Ambil Data Transaksi dari HP Kasir Ini',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Klik tombol di bawah pada HP Kasir 1 / HP Kasir 2 untuk menyalin seluruh paket transaksi & menu, lalu kirimkan ke HP Utama/Owner.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _isSyncBusy
                                          ? null
                                          : () =>
                                              _exportAndCopySyncData(authState),
                                      icon: const Icon(Icons.copy_all_rounded,
                                          size: 18),
                                      label: Text(
                                        'Salin Paket Data ${authState.activeDeviceName} ke Clipboard',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Langkah 2: Tempel & Gabungkan
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Langkah 2: Gabungkan Data dari HP Kasir Lain',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () async {
                                            final data = await Clipboard.getData(
                                                Clipboard.kTextPlain);
                                            if (data?.text != null) {
                                              setState(() {
                                                _importJsonController.text =
                                                    data!.text!;
                                              });
                                            }
                                          },
                                          icon: const Icon(Icons.content_paste,
                                              size: 16),
                                          label: const Text(
                                            'Tempel Clipboard',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextField(
                                      controller: _importJsonController,
                                      maxLines: 4,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace'),
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Tempelkan kode paket data JSON dari HP Kasir 1 / HP Kasir 2 di sini...',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _isSyncBusy
                                          ? null
                                          : _importAndMergeSyncData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                      ),
                                      icon: const Icon(Icons.merge_type_rounded,
                                          size: 18),
                                      label: const Text(
                                        'Gabungkan Transaksi & Menu Sekarang',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (_syncStatusMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (_isSyncSuccess
                                            ? AppColors.success
                                            : AppColors.error)
                                        .withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _isSyncSuccess
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  child: Text(
                                    _syncStatusMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isSyncSuccess
                                          ? AppColors.primaryDark
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),
                              // Tips Penggunaan 2+ HP via Wi-Fi Lokal
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.info.withAlpha(70)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '💡 Tips Menggunakan 2 HP / Tablet Bersamaan:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.info,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '1. Setiap HP Kasir login menggunakan akunnya masing-masing (misal HP 1 login sebagai "kasir1", HP 2 login sebagai "kasir2").\n'
                                      '2. Nomor struk otomatis diberi kode unik per HP (contoh: K1-20261016-xxxx dan K2-20261016-xxxx) sehingga tidak akan pernah bentrok.\n'
                                      '3. Saat tutup shift, cukup salin paket data dari HP Kasir ke HP Owner untuk menggabungkan seluruh grafik analitik & laporan Excel bulanan.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
