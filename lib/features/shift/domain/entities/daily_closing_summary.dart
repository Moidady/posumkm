import 'package:equatable/equatable.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class TopProductSold extends Equatable {
  final String productName;
  final int quantity;
  final int totalSales;

  const TopProductSold({
    required this.productName,
    required this.quantity,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [productName, quantity, totalSales];
}

class DailyClosingSummary extends Equatable {
  final String storeName;
  final String cashierName;
  final DateTime closingDate;
  final int totalOrders;
  final int totalSales;
  final int cashSales; // Uang Tunai (Wajib setor fisik ke Owner)
  final int qrisSales; // Uang QRIS (Dana masuk ke rekening Owner)
  final int startingCash; // Modal awal kasir di laci
  final int cashIn; // Kas masuk tambahan
  final int cashOut; // Kas keluar kecil (beli es batu/plastik)
  final int actualCash; // Uang fisik aktual yang dihitung kasir di laci
  final List<TopProductSold> topProducts;

  const DailyClosingSummary({
    required this.storeName,
    required this.cashierName,
    required this.closingDate,
    required this.totalOrders,
    required this.totalSales,
    required this.cashSales,
    required this.qrisSales,
    required this.startingCash,
    this.cashIn = 0,
    this.cashOut = 0,
    required this.actualCash,
    this.topProducts = const [],
  });

  /// Kas yang seharusnya ada di laci menurut sistem:
  /// Modal Awal + Penjualan Tunai + Kas Masuk - Kas Keluar
  int get systemCash => startingCash + cashSales + cashIn - cashOut;

  /// Selisih kas fisik vs kas sistem
  int get discrepancy => actualCash - systemCash;

  String get discrepancyStatus {
    if (discrepancy == 0) return 'PAS / Sesuai (Rp 0)';
    if (discrepancy > 0) return 'LEBIH (+${CurrencyFormatter.format(discrepancy)})';
    return 'SELISIH KURANG (${CurrencyFormatter.format(discrepancy)})';
  }

  /// Membuat teks rapi berformat WhatsApp dengan emoji dan pemisah ribuan Rupiah
  String toWhatsAppMessage() {
    final buffer = StringBuffer();
    buffer.writeln('📊 *LAPORAN TUTUP TOKO - $storeName*');
    buffer.writeln('Tanggal : ${DateFormatter.formatDayDate(closingDate)}');
    buffer.writeln('Kasir   : $cashierName');
    buffer.writeln('========================================');
    buffer.writeln('💰 *RINGKASAN OMZET*');
    buffer.writeln('Total Pesanan : $totalOrders Transaksi');
    buffer.writeln('*Total Omzet   : ${CurrencyFormatter.format(totalSales)}*');
    buffer.writeln('');
    buffer.writeln('💳 *RINCIAN PEMBAYARAN:*');
    buffer.writeln('• 💵 *Tunai (Cash)* : ${CurrencyFormatter.format(cashSales)} _(Wajib Setor Fisik)_');
    buffer.writeln('• 📱 *QRIS (Bank)*  : ${CurrencyFormatter.format(qrisSales)} _(Masuk Rekening)_');
    buffer.writeln('');

    if (topProducts.isNotEmpty) {
      buffer.writeln('📦 *MENU TERLARIS HARI INI:*');
      for (int i = 0; i < topProducts.length; i++) {
        final p = topProducts[i];
        buffer.writeln('${i + 1}. ${p.productName} : *${p.quantity} Porsi*');
      }
      buffer.writeln('');
    }

    buffer.writeln('💵 *REKAP KAS LACI KASIR:*');
    buffer.writeln('• Modal Awal Kasir : ${CurrencyFormatter.format(startingCash)}');
    buffer.writeln('• Kas Masuk Tunai  : +${CurrencyFormatter.format(cashSales)}');
    if (cashOut > 0) {
      buffer.writeln('• Kas Keluar (Beban): -${CurrencyFormatter.format(cashOut)}');
    }
    buffer.writeln('• Total Uang Fisik : ${CurrencyFormatter.format(actualCash)}');
    buffer.writeln('• Status Selisih   : *$discrepancyStatus*');
    buffer.writeln('========================================');
    buffer.writeln('_Laporan dikirim otomatis dari Aplikasi POS Gerai_');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        storeName,
        cashierName,
        closingDate,
        totalOrders,
        totalSales,
        cashSales,
        qrisSales,
        startingCash,
        cashIn,
        cashOut,
        actualCash,
        topProducts,
      ];
}
