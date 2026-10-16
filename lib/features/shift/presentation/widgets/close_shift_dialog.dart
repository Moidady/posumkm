import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pos_umkm/features/shift/data/datasources/local/shift_local_datasource.dart';
import 'package:pos_umkm/features/shift/data/services/whatsapp_closing_report_service.dart';
import 'package:pos_umkm/features/shift/domain/entities/daily_closing_summary.dart';

class CloseShiftDialog extends StatefulWidget {
  const CloseShiftDialog({super.key});

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _shiftDataSource = ShiftLocalDataSourceImpl();

  final _cashierNameController = TextEditingController(text: 'Kasir 1');
  final _startingCashController = TextEditingController(text: '200000');
  final _actualCashController = TextEditingController();
  final _cashOutController = TextEditingController(text: '0');

  bool _isLoading = false;
  DailyClosingSummary? _summary;
  String? _ownerWhatsApp;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState.currentUser != null) {
      _cashierNameController.text =
          '${authState.currentUser!.fullName} (${authState.activeDeviceName})';
    }
    _loadOwnerPhone();
  }

  Future<void> _loadOwnerPhone() async {
    final phone = await _shiftDataSource.getOwnerWhatsAppNumber();
    if (mounted) {
      setState(() {
        _ownerWhatsApp = phone;
      });
    }
  }

  @override
  void dispose() {
    _cashierNameController.dispose();
    _startingCashController.dispose();
    _actualCashController.dispose();
    _cashOutController.dispose();
    super.dispose();
  }

  Future<void> _calculateSummary() async {
    final cashier = _cashierNameController.text.trim();
    final startingCash = CurrencyFormatter.parse(_startingCashController.text);
    final actualCash = CurrencyFormatter.parse(_actualCashController.text);
    final cashOut = CurrencyFormatter.parse(_cashOutController.text);

    if (_actualCashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah uang fisik aktual yang ada di laci kasir!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final summary = await _shiftDataSource.generateClosingSummary(
        cashierName: cashier.isEmpty ? 'Kasir' : cashier,
        startingCash: startingCash,
        actualCash: actualCash,
        cashOut: cashOut,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storefront_outlined, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Tutup Toko & Rekap Kasir',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Input Data Shift
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cashierNameController,
                              decoration: const InputDecoration(labelText: 'Nama Kasir'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _startingCashController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Modal Awal Kasir'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _actualCashController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Uang Fisik di Laci *',
                                hintText: 'Hitung fisik laci...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cashOutController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kas Keluar (Es/Plastik)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tombol Hitung
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _calculateSummary,
                          icon: const Icon(Icons.calculate_outlined, size: 18),
                          label: Text(_isLoading ? 'Menghitung...' : 'Hitung Rekapitulasi Hari Ini'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tampilan Hasil Rekapitulasi
                      if (_summary != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Omzet Hari Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    CurrencyFormatter.format(_summary!.totalSales),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Tunai vs QRIS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('💵 Uang Tunai (Wajib Setor Fisik):', style: TextStyle(fontSize: 12)),
                                  Text(
                                    CurrencyFormatter.format(_summary!.cashSales),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('📱 QRIS (Masuk Rekening Bank):', style: TextStyle(fontSize: 12)),
                                  Text(
                                    CurrencyFormatter.format(_summary!.qrisSales),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.info),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Selisih Kas
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Kas Sistem (Seharusnya):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(_summary!.systemCash), style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Uang Fisik Aktual:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(CurrencyFormatter.format(_summary!.actualCash), style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Status Selisih Kas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    _summary!.discrepancyStatus,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _summary!.discrepancy == 0 ? AppColors.success : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tombol Kirim WhatsApp ke Owner
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final phone = _ownerWhatsApp ?? '081234567890';
                              WhatsAppClosingReportService.sendReportToOwner(
                                rawPhoneNumber: phone,
                                summary: _summary!,
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Kirim Laporan ke WhatsApp Owner',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
