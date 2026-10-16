import 'package:flutter/material.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/core/utils/date_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/entities/digital_receipt.dart';
import 'package:pos_umkm/features/checkout/presentation/widgets/digital_receipt_dialog.dart';
import 'package:pos_umkm/features/history_and_reports/data/datasources/local/history_local_datasource.dart';
import 'package:pos_umkm/features/settings/presentation/widgets/owner_pin_dialog.dart';

class OrderHistoryDialog extends StatefulWidget {
  const OrderHistoryDialog({super.key});

  @override
  State<OrderHistoryDialog> createState() => _OrderHistoryDialogState();
}

class _OrderHistoryDialogState extends State<OrderHistoryDialog>
    with SingleTickerProviderStateMixin {
  final HistoryLocalDataSource _dataSource = HistoryLocalDataSource();
  late TabController _tabController;

  List<DigitalReceipt> _receipts = [];
  List<CashMovementRecord> _cashMovements = [];
  bool _isLoading = true;

  // Controllers Kas Keluar/Masuk
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  String _movementType = 'OUT';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _dataSource.getTodayOrders();
      final movements = await _dataSource.getTodayCashMovements();
      if (!mounted) return;
      setState(() {
        _receipts = orders;
        _cashMovements = movements;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVoidOrder(DigitalReceipt receipt) async {
    final authorized = await OwnerPinDialog.verify(
      context,
      title: 'Otorisasi Void Pesanan',
      subtitle:
          'Masukkan PIN Owner untuk membatalkan pesanan ${receipt.order.orderNumber} (${CurrencyFormatter.format(receipt.order.totalAmount)}).',
    );
    if (!authorized || !mounted) return;

    await _dataSource.voidOrder(
      orderId: receipt.order.id,
      reason: 'Dibatalkan oleh Owner',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${receipt.order.orderNumber} berhasil di-VOID.'),
        backgroundColor: AppColors.warning,
      ),
    );
    _loadData();
  }

  Future<void> _addCashMovement() async {
    final amount = CurrencyFormatter.parse(_amountCtrl.text);
    final notes = _notesCtrl.text.trim();

    if (amount <= 0 || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal (Rp) dan keterangan kas wajib diisi!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await _dataSource.addCashMovement(
      type: _movementType,
      amount: amount,
      notes: notes,
    );

    _amountCtrl.clear();
    _notesCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mutasi kas berhasil dicatat ke laci shift!'),
        backgroundColor: AppColors.success,
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final paidOrders = _receipts.where((r) => r.order.status == 'PAID').toList();
    final totalOmzet = paidOrders.fold<int>(0, (s, r) => s + r.order.totalAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi & Kas Laci Hari Ini',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    text: 'Transaksi Hari Ini (${_receipts.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    text: 'Kas Keluar / Masuk (${_cashMovements.length})',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // ==========================================
                          // TAB 1: RIWAYAT TRANSAKSI
                          // ==========================================
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Transaksi Lunas: ${paidOrders.length} Pesanan',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total Omzet Bersih: ${CurrencyFormatter.format(totalOmzet)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _receipts.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Belum ada transaksi hari ini.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _receipts.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, idx) {
                                          final r = _receipts[idx];
                                          final o = r.order;
                                          final isVoid = o.status == 'VOID';
                                          final isQris = o.paymentMethod == 'QRIS';

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: isVoid
                                                  ? AppColors.errorLight
                                                  : (isQris
                                                      ? AppColors.primary
                                                          .withAlpha(25)
                                                      : AppColors.successLight),
                                              child: Icon(
                                                isVoid
                                                    ? Icons.cancel_outlined
                                                    : (isQris
                                                        ? Icons.qr_code
                                                        : Icons.payments_outlined),
                                                color: isVoid
                                                    ? AppColors.error
                                                    : (isQris
                                                        ? AppColors.primary
                                                        : AppColors.success),
                                                size: 20,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Text(
                                                  o.orderNumber,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isVoid
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
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
                                                    color: isVoid
                                                        ? AppColors.errorLight
                                                        : AppColors.background,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isVoid
                                                        ? 'VOID / BATAL'
                                                        : (isQris
                                                            ? 'QRIS (${o.qrisReferenceNo ?? "-"})'
                                                            : 'TUNAI'),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isVoid
                                                          ? AppColors.error
                                                          : AppColors
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Text(
                                              '${DateFormatter.formatDateTime(o.createdAt)} • ${o.items.map((i) => "${i.quantity}x ${i.productName}").join(", ")}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  CurrencyFormatter.format(
                                                      o.totalAmount),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isVoid
                                                        ? AppColors.error
                                                        : AppColors.textPrimary,
                                                    decoration: isVoid
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Lihat Struk Digital',
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    size: 20,
                                                    color: AppColors.primary,
                                                  ),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          DigitalReceiptDialog(
                                                        receipt: r,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                if (!isVoid)
                                                  IconButton(
                                                    tooltip:
                                                        'Void / Batalkan Pesanan (PIN Owner)',
                                                    icon: const Icon(
                                                      Icons.block,
                                                      size: 20,
                                                      color: AppColors.error,
                                                    ),
                                                    onPressed: () =>
                                                        _handleVoidOrder(r),
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
                          // TAB 2: KAS KELUAR / MASUK LACI
                          // ==========================================
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Catat Pengeluaran / Pemasukan Kas Kecil Laci',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child:
                                              DropdownButtonFormField<String>(
                                            initialValue: _movementType,
                                            decoration: const InputDecoration(
                                              labelText: 'Jenis Kas',
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'OUT',
                                                child: Text(
                                                    'Kas Keluar (Beli Bahan/Es)'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'IN',
                                                child: Text(
                                                    'Kas Masuk (Tambah Modal)'),
                                              ),
                                            ],
                                            onChanged: (v) {
                                              if (v != null) {
                                                setState(
                                                    () => _movementType = v);
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: _amountCtrl,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Nominal (Rp)',
                                              hintText: '15000',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: _notesCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Keterangan',
                                              hintText: 'Beli es batu / plastik',
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _addCashMovement,
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _cashMovements.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Belum ada pengeluaran/pemasukan kas kecil hari ini.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _cashMovements.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, idx) {
                                          final m = _cashMovements[idx];
                                          final isOut = m.type == 'OUT';
                                          return ListTile(
                                            leading: Icon(
                                              isOut
                                                  ? Icons.arrow_circle_up
                                                  : Icons.arrow_circle_down,
                                              color: isOut
                                                  ? AppColors.error
                                                  : AppColors.success,
                                            ),
                                            title: Text(
                                              m.notes,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              DateFormatter.formatDateTime(
                                                  m.createdAt),
                                            ),
                                            trailing: Text(
                                              '${isOut ? "-" : "+"}${CurrencyFormatter.format(m.amount)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isOut
                                                    ? AppColors.error
                                                    : AppColors.success,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
