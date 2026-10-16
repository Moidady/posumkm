import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pos_umkm/core/theme/app_colors.dart';
import 'package:pos_umkm/core/utils/currency_formatter.dart';
import 'package:pos_umkm/features/history_and_reports/data/datasources/local/analytics_local_datasource.dart';
import 'package:pos_umkm/features/history_and_reports/data/services/excel_export_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsLocalDataSource _dataSource = AnalyticsLocalDataSource();

  String _selectedPeriod = 'MONTH'; // 'TODAY', '7DAYS', 'MONTH', 'ALL'
  String _selectedDevice = 'ALL';
  bool _isLoading = true;
  AnalyticsDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _dataSource.loadDashboardData(
        period: _selectedPeriod,
        deviceFilter: _selectedDevice,
      );
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat analitik: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadExcel() async {
    try {
      final saved = await ExcelExportService().exportMonthlyReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Laporan Excel berhasil diunduh: $saved'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ekspor Excel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Dashboard Analitik & Grafik Penjualan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang Grafik',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _downloadExcel,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text(
                'Unduh Excel (.xlsx)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading || _data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // 1. FILTER PERIODE & FILTER HP KASIR
                    // ==========================================
                    _buildFilterSection(_data!),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 2. KARTU RINGKASAN UTAMA (KPI CARDS)
                    // ==========================================
                    _buildKpiCards(_data!),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 3. PROPORSI TUNAI VS QRIS
                    // ==========================================
                    _buildPaymentSplitCard(_data!),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 4. GRAFIK TREN OMZET HARIAN & JAM RAMAI
                    // ==========================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 850) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildDailyTrendChart(_data!)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPeakHoursChart(_data!)),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildDailyTrendChart(_data!),
                            const SizedBox(height: 16),
                            _buildPeakHoursChart(_data!),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 5. TOP MENU TERLARIS & KATEGORI OUTLET
                    // ==========================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 850) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildTopMenusCard(_data!),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildCategoryPerformanceCard(_data!),
                                    const SizedBox(height: 16),
                                    _buildMultiDevicePerformanceCard(_data!),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildTopMenusCard(_data!),
                            const SizedBox(height: 16),
                            _buildCategoryPerformanceCard(_data!),
                            const SizedBox(height: 16),
                            _buildMultiDevicePerformanceCard(_data!),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterSection(AnalyticsDashboardData data) {
    final periods = [
      {'id': 'TODAY', 'label': 'Hari Ini'},
      {'id': '7DAYS', 'label': '7 Hari Terakhir'},
      {'id': 'MONTH', 'label': 'Bulan Ini'},
      {'id': 'ALL', 'label': 'Semua Waktu'},
    ];

    final devices = <String>{'ALL', ...data.availableDevices}.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: periods.map((p) {
              final isSelected = _selectedPeriod == p['id'];
              return ChoiceChip(
                label: Text(p['label']!),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() => _selectedPeriod = p['id']!);
                  _loadData();
                },
              );
            }).toList(),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_android_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Filter HP Kasir:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: devices.contains(_selectedDevice)
                    ? _selectedDevice
                    : 'ALL',
                underline: const SizedBox.shrink(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                items: devices.map((dev) {
                  return DropdownMenuItem(
                    value: dev,
                    child: Text(dev == 'ALL' ? 'Semua HP Kasir' : dev),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDevice = val);
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCards(AnalyticsDashboardData data) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpiCard(
          title: 'Total Omzet Bersih',
          value: CurrencyFormatter.format(data.totalOmzet),
          subtitle: 'Dari ${data.totalOrders} transaksi lunas',
          icon: Icons.payments_rounded,
          color: AppColors.primary,
        ),
        _kpiCard(
          title: 'Rata-rata Belanja',
          value: CurrencyFormatter.format(data.averageBasketSize),
          subtitle: 'Nilai rata-rata per struk pelanggan',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.info,
        ),
        _kpiCard(
          title: 'Total Menu Terjual',
          value: '${data.totalItemsSold} Porsi',
          subtitle: 'Akumulasi makanan & minuman',
          icon: Icons.fastfood_rounded,
          color: AppColors.success,
        ),
        _kpiCard(
          title: 'Jam Paling Ramai (Peak)',
          value: data.busiestHourRange,
          subtitle: 'Siapkan stok lebih banyak di jam ini',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 265,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSplitCard(AnalyticsDashboardData data) {
    final total = data.totalOmzet;
    final cashPct = total > 0 ? (data.cashOmzet / total) : 0.5;
    final qrisPct = total > 0 ? (data.qrisOmzet / total) : 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Proporsi Pembayaran: Tunai (Cash) vs QRIS',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  Expanded(
                    flex: max(1, (cashPct * 100).round()),
                    child: Container(color: AppColors.success),
                  ),
                  Expanded(
                    flex: max(1, (qrisPct * 100).round()),
                    child: Container(color: AppColors.info),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tunai: ${CurrencyFormatter.format(data.cashOmzet)} '
                    '(${total > 0 ? (cashPct * 100).toStringAsFixed(1) : "0"}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'QRIS: ${CurrencyFormatter.format(data.qrisOmzet)} '
                    '(${total > 0 ? (qrisPct * 100).toStringAsFixed(1) : "0"}%)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChart(AnalyticsDashboardData data) {
    final maxSales = data.dailyTrend.fold<int>(
      0,
      (prev, e) => e.totalSales > prev ? e.totalSales : prev,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Grafik Tren Omzet Harian',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Perbandingan omzet penjualan per hari pada periode terpilih',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (data.dailyTrend.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Belum ada data transaksi pada periode ini.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.dailyTrend.map((point) {
                    final ratio =
                        maxSales > 0 ? (point.totalSales / maxSales) : 0.0;
                    final barHeight = max(8.0, ratio * 130.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Tooltip(
                        message:
                            '${point.dateKey}\nOmzet: ${CurrencyFormatter.format(point.totalSales)}\nTransaksi: ${point.orderCount} struk',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              point.totalSales > 0
                                  ? '${(point.totalSales / 1000).round()}rb'
                                  : '0',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: barHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: point.totalSales > 0
                                      ? [
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ]
                                      : [
                                          AppColors.cardBorder,
                                          AppColors.cardBorder,
                                        ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              point.shortLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${point.orderCount}x',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart(AnalyticsDashboardData data) {
    final maxOrders = data.hourlyPeak.fold<int>(
      0,
      (prev, e) => e.orderCount > prev ? e.orderCount : prev,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled_rounded,
                  size: 20, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Grafik Jam Ramai Pelanggan (Peak Hours)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribusi jumlah transaksi berdasarkan jam operasional (08:00 - 22:00)',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.hourlyPeak.map((point) {
                  final ratio =
                      maxOrders > 0 ? (point.orderCount / maxOrders) : 0.0;
                  final barHeight = max(8.0, ratio * 130.0);
                  final isPeak =
                      maxOrders > 0 && point.orderCount == maxOrders;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Tooltip(
                      message:
                          'Jam ${point.hourLabel}\n${point.orderCount} Transaksi\nOmzet: ${CurrencyFormatter.format(point.totalSales)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${point.orderCount}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPeak
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 24,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: isPeak
                                  ? AppColors.warning
                                  : (point.orderCount > 0
                                      ? AppColors.info
                                      : AppColors.cardBorder),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.hourLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isPeak ? FontWeight.bold : FontWeight.normal,
                              color: isPeak
                                  ? AppColors.warning
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMenusCard(AnalyticsDashboardData data) {
    final maxQty = data.topMenus.isNotEmpty ? data.topMenus.first.totalQty : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  size: 20, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Peringkat Menu Terlaris (Best Sellers)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Urutan menu dengan jumlah porsi terjual & kontribusi omzet tertinggi',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Divider(height: 20),
          if (data.topMenus.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Belum ada menu terjual pada periode ini. Buat transaksi di kasir untuk melihat grafik menu terlaris.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(12, data.topMenus.length),
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = data.topMenus[index];
                final progress = maxQty > 0 ? (item.totalQty / maxQty) : 0.0;

                return Row(
                  children: [
                    // Badge Peringkat
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index < 3
                            ? AppColors.warning.withAlpha(35)
                            : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: index < 3
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Thumbnail Produk
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl.isNotEmpty
                          ? Image.asset(
                              item.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: AppColors.primary.withAlpha(20),
                                child: const Icon(Icons.fastfood,
                                    size: 20, color: AppColors.primary),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: AppColors.primary.withAlpha(20),
                              child: const Icon(Icons.fastfood,
                                  size: 20, color: AppColors.primary),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Nama, Kategori, & Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.totalQty} Porsi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.categoryName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.totalSales),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: AppColors.background,
                              color: index == 0
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceCard(AnalyticsDashboardData data) {
    final totalSales = max(1, data.totalOmzet);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded,
                  size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Kontribusi Per Kategori Menu',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          if (data.categoryBreakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data kategori.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...data.categoryBreakdown.map((cat) {
              final pct = (cat.totalSales / totalSales).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${cat.totalQty} porsi • ${CurrencyFormatter.format(cat.totalSales)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 7,
                        backgroundColor: AppColors.background,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMultiDevicePerformanceCard(AnalyticsDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.devices_rounded, size: 20, color: AppColors.info),
              SizedBox(width: 8),
              Text(
                'Rekap Performa Per HP / Kasir',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Rincian omzet dari masing-masing perangkat HP/Tablet kasir',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Divider(height: 20),
          if (data.deviceBreakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada transaksi kasir tercatat.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...data.deviceBreakdown.map((dev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_android_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${dev.deviceName} (${dev.cashierName})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(dev.totalSales),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dev.orderCount} Transaksi  •  Tunai: ${CurrencyFormatter.format(dev.cashSales)}  •  QRIS: ${CurrencyFormatter.format(dev.qrisSales)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
