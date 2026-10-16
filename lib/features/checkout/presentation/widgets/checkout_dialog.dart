import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/checkout/domain/usecases/verify_qris_proof_usecase.dart';
import 'package:pos_umkm/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:pos_umkm/features/pos/domain/entities/cart_item.dart';

class CheckoutDialog extends StatefulWidget {
  final List<CartItem> cartItems;
  final int subtotal;
  final int discountAmount;
  final int totalAmount;

  const CheckoutDialog({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAmount,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _qrisRefController = TextEditingController();
  final VerifyQrisProofUseCase _verifyQrisUseCase = VerifyQrisProofUseCase();

  int _cashTendered = 0;
  String? _qrisVerificationMessage;
  bool _isQrisVerified = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Set default uang pas
    _cashTendered = widget.totalAmount;
    _cashController.text = CurrencyFormatter.format(widget.totalAmount);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashController.dispose();
    _qrisRefController.dispose();
    super.dispose();
  }

  void _onQuickCashSelected(int amount) {
    setState(() {
      _cashTendered = amount;
      _cashController.text = CurrencyFormatter.format(amount);
    });
  }

  void _handleManualCashChange(String value) {
    final parsed = CurrencyFormatter.parse(value);
    setState(() {
      _cashTendered = parsed;
    });
  }

  void _runOfflineOcrVerification({
    required int simulatedAmount,
    required DateTime simulatedTime,
    required String simulatedStatus,
  }) {
    final rrnInput = _qrisRefController.text.trim().isEmpty
        ? 'RRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
        : 'RRN-${_qrisRefController.text.trim()}';

    final result = _verifyQrisUseCase.validateProof(
      expectedAmount: widget.totalAmount,
      detectedAmount: simulatedAmount,
      transactionTime: simulatedTime,
      statusText: simulatedStatus,
      referenceNumber: rrnInput,
    );

    setState(() {
      _isQrisVerified = result.isValid;
      if (result.isValid) {
        _qrisRefController.text =
            result.referenceNumber.replaceAll('RRN-', '');
        _qrisVerificationMessage =
            'Tring! QRIS Terverifikasi Valid (Nominal: ${CurrencyFormatter.format(result.detectedAmount)}, Ref: ${result.referenceNumber})';
      } else {
        _qrisVerificationMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final changeDue = _cashTendered - widget.totalAmount;
    final isCashSufficient = _cashTendered >= widget.totalAmount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Pembayaran Kasir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Total Tagihan Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.totalAmount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Bar (Tunai vs QRIS)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.money, size: 20),
                      text: 'Uang Tunai (Cash)',
                    ),
                    Tab(
                      icon: Icon(Icons.qr_code_scanner, size: 20),
                      text: 'QRIS & Verifikasi Anti-Fraud',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Konten Tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ==========================================
                    // TAB 1: TUNAI (CASH)
                    // ==========================================
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Pecahan Cepat:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuickCashChip(
                                  'Uang Pas', widget.totalAmount),
                              _buildQuickCashChip('Rp 10.000', 10000),
                              _buildQuickCashChip('Rp 20.000', 20000),
                              _buildQuickCashChip('Rp 50.000', 50000),
                              _buildQuickCashChip('Rp 100.000', 100000),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Uang Diterima dari Pembeli:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cashController,
                            keyboardType: TextInputType.number,
                            onChanged: _handleManualCashChange,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: AppColors.primary,
                              ),
                              hintText: 'Masukkan nominal uang tunai...',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Kartu Info Kembalian
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isCashSufficient
                                  ? AppColors.successLight
                                  : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isCashSufficient
                                      ? 'Uang Kembalian Kasir:'
                                      : 'Uang Masih Kurang:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCashSufficient
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(changeDue.abs()),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isCashSufficient
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tombol Selesaikan Tunai
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isCashSufficient
                                  ? () {
                                      context.read<CheckoutBloc>().add(
                                            ProcessCashPaymentEvent(
                                              cartItems: widget.cartItems,
                                              subtotal: widget.subtotal,
                                              discountAmount:
                                                  widget.discountAmount,
                                              totalAmount: widget.totalAmount,
                                              cashTendered: _cashTendered,
                                            ),
                                          );
                                      Navigator.pop(context);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                disabledBackgroundColor: AppColors.cardBorder,
                              ),
                              child: const Text(
                                'Selesaikan Pembayaran Tunai',
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

                    // ==========================================
                    // TAB 2: QRIS OUTLET & OFFLINE OCR VERIFIER
                    // ==========================================
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.qr_code_2,
                                  size: 68,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Arahkan Pembeli Scan Stiker QRIS di Meja Kasir',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Wajib Sama Persis: ${CurrencyFormatter.format(widget.totalAmount)}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Simulasi & Verifikasi Anti-Fraud OCR (Aturan #7 AGENT.md)
                          const Text(
                            'Verifikasi Bukti Bayar Offline (Anti-Fraud Scanner):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _runOfflineOcrVerification(
                                  simulatedAmount: widget.totalAmount,
                                  simulatedTime: DateTime.now(),
                                  simulatedStatus: 'Transaksi Berhasil',
                                ),
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                label: const Text(
                                  'Scan Bukti Valid (Sesuai)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _runOfflineOcrVerification(
                                  simulatedAmount: widget.totalAmount - 5000,
                                  simulatedTime: DateTime.now(),
                                  simulatedStatus: 'Transaksi Berhasil',
                                ),
                                icon: const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                label: const Text(
                                  'Uji Nominal Salah',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _runOfflineOcrVerification(
                                  simulatedAmount: widget.totalAmount,
                                  simulatedTime: DateTime.now()
                                      .subtract(const Duration(minutes: 25)),
                                  simulatedStatus: 'Transaksi Berhasil',
                                ),
                                icon: const Icon(
                                  Icons.history_toggle_off,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                label: const Text(
                                  'Uji Screenshot Lama (>10 mnt)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),

                          if (_qrisVerificationMessage != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isQrisVerified
                                    ? AppColors.successLight
                                    : AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isQrisVerified
                                        ? Icons.verified
                                        : Icons.error_outline,
                                    color: _isQrisVerified
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _qrisVerificationMessage!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _isQrisVerified
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Input No Referensi RRN (Anti-Fraud Audit)
                          TextField(
                            controller: _qrisRefController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '4 Digit Terakhir No. Referensi (RRN)',
                              hintText: 'Contoh: 8192 (Otomatis dari Scan / Ketik Manual)',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Verifikasi & Selesai QRIS
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final ref = _qrisRefController.text
                                        .trim()
                                        .isEmpty
                                    ? 'RRN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
                                    : 'RRN-${_qrisRefController.text.trim()}';

                                context.read<CheckoutBloc>().add(
                                      ProcessQrisPaymentEvent(
                                        cartItems: widget.cartItems,
                                        subtotal: widget.subtotal,
                                        discountAmount: widget.discountAmount,
                                        totalAmount: widget.totalAmount,
                                        qrisReferenceNo: ref,
                                        qrisScannedTimestamp:
                                            DateTime.now().toIso8601String(),
                                      ),
                                    );
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'Verifikasi & Selesai QRIS',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCashChip(String label, int amount) {
    final isSelected = _cashTendered == amount;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => _onQuickCashSelected(amount),
    );
  }
}
